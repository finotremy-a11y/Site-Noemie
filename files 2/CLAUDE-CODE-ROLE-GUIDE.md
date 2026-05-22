# Rails 8 Enterprise Premium - Claude Code Execution Guide
## 90%+ Coverage for Sensitive Data & Payment Applications

This document provides detailed instructions for executing a **premium Rails 8 application** with **90%+ test coverage** for critical systems (Doctolib-like, fintech, healthcare).

Total execution time: **24 hours** of expert-led development.

---

## Overview: Critical Path Focus

Rather than equal coverage across all code, premium apps focus on:

```
Testing Strategy:
├─ Critical code (login, payments, appointments): 95%+
├─ Important code (API, controllers): 90%+
├─ Supporting code (jobs, mailers): 85%+
└─ Overall: 90%+
```

---

## Role 1: Senior Architect

**Duration**: 2 hours
**Focus**: Zero-defect architecture for sensitive operations

### Key Decisions for Premium App

```bash
# 1. Payment Processing
# Decision: Use Stripe (PCI-compliant), NOT raw card processing
# Why: PCI-DSS Level 1, handles security for you

# 2. Data Consistency
# Decision: ACID transactions, pessimistic locking for appointments
# Why: Prevents double-booking, payment issues

# 3. Disaster Recovery
# Decision: Master-replica replication, hourly snapshots
# Why: Can restore to any point in last 30 days

# 4. Monitoring
# Decision: < 5 min detection of issues
# Why: Faster response = less data loss/exposure
```

### Prompt for Claude Code

```
Act as Senior Architect for a Doctolib-like healthcare booking + payment system.

Design the architecture:

1. System Architecture:
   - Web tier: Rails app (stateless, auto-scaling)
   - Database tier: PostgreSQL (master-replica, real-time sync)
   - Cache: Redis (sessions, appointment cache)
   - Payment: Stripe (PCI-DSS compliant)
   - Queue: Sidekiq (notifications, emails)
   - CDN: CloudFront (static assets)

2. Critical Paths (These MUST work flawlessly):
   - Doctor login → access schedule
   - Patient signup → book appointment
   - Appointment confirmation → notify both
   - Payment processing → invoice generation
   - Appointment cancellation → refund processing
   - Patient data access → audit logged

3. Safety Mechanisms:
   - Pessimistic locking on appointment slots
   - Idempotency keys for payments
   - Transaction rollback on payment failure
   - Automatic retry for failed notifications
   - Audit logging for sensitive data access

4. Disaster Recovery:
   - RTO (Recovery Time Objective): < 30 minutes
   - RPO (Recovery Point Objective): < 5 minutes
   - Tested recovery procedures for:
     * Database corruption
     * Payment gateway down
     * Notification service down
     * Complete server failure

5. Scalability Plan:
   - MVP: Single server (100 concurrent users)
   - Growth: Load balancer + 2-3 app servers (1000 concurrent)
   - Scale: Multi-region failover (10,000+ concurrent)

Application: Doctolib-like healthcare booking system
Expected users: 10,000 initial, 100,000 in 1 year
Payment volume: $100K/month
Critical data: Patient appointments, medical history
```

---

## Role 2: Backend Lead Developer

**Duration**: 4 hours
**Focus**: Critical business logic with defensive coding

### Premium Requirements

```ruby
# Models MUST have:
# 1. Database-level constraints (NOT just validations)
# 2. Associations with dependent: :destroy carefully
# 3. Scopes for filtering securely
# 4. Callbacks for audit logging

# Services MUST have:
# 1. Transaction wrapping for multi-step operations
# 2. Idempotency handling for payment operations
# 3. Comprehensive error handling
# 4. Audit logging on sensitive operations

# API MUST have:
# 1. Input validation (strong_parameters)
# 2. Authorization checks (Pundit policies)
# 3. Rate limiting on critical endpoints
# 4. Detailed error messages (without exposing sensitive data)
```

### Critical Models to Create

```ruby
# User (Doctor or Patient)
class User < ApplicationRecord
  # Validations
  validates :email, presence: true, uniqueness: true
  validates :password, length: { minimum: 12 }
  validates :phone, presence: true, format: { with: /\A\+?[\d\s\-\(\)]{10,}\z/ }
  
  # Encryptions
  encrypt :phone, :ssn, :address  # Sensitive data encrypted at DB level
  
  # Associations
  has_many :appointments, dependent: :destroy
  has_many :payments, dependent: :destroy
  has_many :audit_logs, dependent: :destroy
  
  # Audit logging
  after_create :log_creation
  after_update :log_update
  
  def log_creation
    AuditLog.create(user: self, action: 'created', resource: 'User')
  end
  
  def log_update
    AuditLog.create(user: self, action: 'updated', resource: 'User', changes: saved_changes)
  end
end

# Appointment (Critical path - must test thoroughly)
class Appointment < ApplicationRecord
  # Lock to prevent double-booking
  pessimistic_locking
  
  validates :start_time, presence: true
  validates :end_time, presence: true
  validate :appointment_times_valid
  validate :no_double_booking
  
  belongs_to :doctor, class_name: 'User'
  belongs_to :patient, class_name: 'User'
  has_one :payment, dependent: :nullify
  has_many :notifications, dependent: :destroy
  has_many :audit_logs, dependent: :destroy
  
  # Scopes
  scope :upcoming, -> { where('start_time > ?', Time.current) }
  scope :past, -> { where('end_time < ?', Time.current) }
  scope :for_doctor, ->(doctor) { where(doctor: doctor) }
  scope :for_patient, ->(patient) { where(patient: patient) }
  
  # States
  enum status: { pending: 0, confirmed: 1, completed: 2, cancelled: 3 }
  
  # Callback
  after_create :notify_both_parties
  after_update :log_changes
  
  def notify_both_parties
    SendAppointmentConfirmationJob.perform_later(self)
  end
  
  private
  
  def appointment_times_valid
    return if end_time.blank? || start_time.blank?
    if end_time <= start_time
      errors.add(:end_time, "must be after start time")
    end
  end
  
  def no_double_booking
    # Check if doctor already has appointment at this time
    conflicting = Appointment.where(doctor: doctor, status: [:pending, :confirmed])
                             .where("(start_time, end_time) OVERLAPS (?, ?)", start_time, end_time)
    if conflicting.exists?
      errors.add(:base, "Doctor not available at this time")
    end
  end
end

# Payment (Critical path - must test thoroughly)
class Payment < ApplicationRecord
  validates :amount, presence: true, numericality: { greater_than: 0 }
  validates :stripe_payment_intent_id, presence: true, uniqueness: true
  
  belongs_to :appointment
  belongs_to :user
  has_many :refunds, dependent: :destroy
  has_many :audit_logs, dependent: :destroy
  
  enum status: { pending: 0, completed: 1, failed: 2, refunded: 3 }
  
  # CRITICAL: Use Stripe for payment processing, NOT raw cards
  def charge_card(stripe_token)
    raise "Payment already processed" if completed?
    
    intent = Stripe::PaymentIntent.create(
      amount: (amount * 100).to_i,  # Convert to cents
      currency: 'usd',
      payment_method: stripe_token,
      confirm: true,
      idempotency_key: "payment-#{id}-#{amount}"  # Prevent double-charging
    )
    
    update(stripe_payment_intent_id: intent.id, status: :completed)
    AuditLog.create(resource: 'Payment', action: 'completed', user: user)
    true
  rescue Stripe::CardError => e
    update(status: :failed)
    AuditLog.create(resource: 'Payment', action: 'failed', user: user, details: e.message)
    false
  end
  
  def refund!(reason = nil)
    raise "Cannot refund non-completed payment" unless completed?
    
    Stripe::Refund.create(payment_intent: stripe_payment_intent_id)
    update(status: :refunded)
    Refund.create(payment: self, reason: reason)
    AuditLog.create(resource: 'Payment', action: 'refunded', user: user)
    true
  rescue Stripe::InvalidRequestError => e
    AuditLog.create(resource: 'Payment', action: 'refund_failed', user: user, details: e.message)
    false
  end
end
```

### Service Layer (Business Logic)

```ruby
# app/services/appointment_service.rb
class AppointmentService
  attr_reader :appointment, :errors
  
  def initialize(doctor:, patient:, start_time:, end_time:, cost:)
    @doctor = doctor
    @patient = patient
    @start_time = start_time
    @end_time = end_time
    @cost = cost
    @errors = []
  end
  
  def book_appointment
    ActiveRecord::Base.transaction do
      # 1. Check availability (with lock to prevent race condition)
      doctor_lock = User.lock.find(@doctor.id)
      
      if doctor_has_conflict?
        @errors << "Doctor not available at this time"
        return false
      end
      
      # 2. Create appointment
      @appointment = Appointment.create!(
        doctor: @doctor,
        patient: @patient,
        start_time: @start_time,
        end_time: @end_time,
        cost: @cost,
        status: :pending
      )
      
      # 3. Create associated payment
      Payment.create!(
        appointment: @appointment,
        user: @patient,
        amount: @cost,
        status: :pending
      )
      
      # 4. Queue notification
      SendAppointmentConfirmationJob.perform_later(@appointment.id)
      
      # 5. Log audit
      AuditLog.create(
        resource: 'Appointment',
        action: 'created',
        user: @patient,
        details: "Booked with Dr. #{@doctor.name}"
      )
      
      true
    rescue ActiveRecord::RecordInvalid => e
      @errors << e.message
      false
    rescue => e
      @errors << "Unexpected error: #{e.message}"
      false
    end
  end
  
  private
  
  def doctor_has_conflict?
    Appointment.where(doctor: @doctor, status: [:pending, :confirmed])
               .where("(start_time, end_time) OVERLAPS (?, ?)", @start_time, @end_time)
               .exists?
  end
end
```

### Prompt for Claude Code

```
Act as Backend Lead Developer for Doctolib-like healthcare system.

Generate:

1. All Models with Validations:
   - User (Doctor/Patient)
   - Appointment (with pessimistic locking)
   - Payment (Stripe integration, NOT raw cards)
   - Notification (SMS/Email)
   - AuditLog (every sensitive action)
   - Refund (refund processing)

2. Service Layer:
   - AppointmentService (book, cancel, reschedule)
   - PaymentService (charge card, handle failures, retries)
   - NotificationService (send confirmations, reminders)
   - RefundService (process refunds safely)

3. API Controllers:
   - AppointmentsController (CRUD with authorization)
   - PaymentsController (charge with Stripe)
   - UsersController (profile management)
   - With proper error handling & 404s

4. Routes (config/routes.rb):
   - API v1 versioning
   - Nested resources (doctor/appointments, patient/appointments)
   - Payment webhook endpoint

5. Database Migrations:
   - All tables with proper indexes
   - Foreign keys with proper constraints
   - Encryption fields for sensitive data
   - Audit table for logging

6. Gemfile:
   - Devise for authentication
   - Stripe for payments
   - Pundit for authorization
   - Sidekiq for background jobs
   - pg_enum for appointment statuses

Database: PostgreSQL
Critical paths: Appointments, Payments, User auth
Sensitive data: Phone, SSN, medical history
Payment: Stripe only (no raw cards)
```

---

## Role 3: Frontend/UX Lead (with frontend-design)

**Duration**: 3 hours
**Focus**: Distinctive design + critical action confirmations

### Premium Requirements

```
✅ Distinctive design (NOT generic AI aesthetics)
✅ WCAG 2.1 AA accessibility (doctors/patients with disabilities)
✅ Mobile-first (doctors check schedule on phone)
✅ Confirmation dialogs for critical actions (cancel appointment, process payment)
✅ Real-time updates (appointment status, notifications)
✅ Payment UX: PCI-DSS compliant (use Stripe Elements, no card data in DOM)
✅ Error messages: Clear, no sensitive data exposed
✅ Offline support: Queue actions when offline
```

### Key Views

```erb
<!-- app/views/appointments/show.html.erb -->
<!-- Appointment details with critical action confirmations -->

<div class="appointment-details">
  <h1><%= @appointment.doctor.name %> - <%= @appointment.start_time %></h1>
  
  <% if user_can_modify?(@appointment) %>
    <!-- Confirm before cancelling -->
    <%= button_to "Cancel Appointment", @appointment, method: :delete,
        data: { turbo_confirm: "Are you sure? This will cancel the appointment and process a refund." },
        class: "btn btn-danger" %>
  <% end %>
  
  <!-- Real-time status updates via Turbo -->
  <%= turbo_stream_from @appointment %>
</div>

<!-- Payment form - PCI-DSS compliant (never card data in form) -->
<div id="payment-form">
  <form id="stripe-form">
    <div id="card-element"></div>
    <button id="submit-btn" type="submit">Pay $<%= @payment.amount %></button>
  </form>
  <div id="payment-message" class="hidden"></div>
</div>

<script>
  // CRITICAL: Use Stripe Elements, NOT raw input
  const stripe = Stripe('pk_test_...');
  const elements = stripe.elements();
  const cardElement = elements.create('card');
  cardElement.mount('#card-element');
  
  document.getElementById('stripe-form').addEventListener('submit', handlePayment);
  
  async function handlePayment(e) {
    e.preventDefault();
    const { paymentIntent, error } = await stripe.confirmCardPayment(
      clientSecret,
      { payment_method: { card: cardElement } }
    );
    
    if (error) {
      document.getElementById('payment-message').textContent = error.message;
    } else {
      // Success - redirect to confirmation
      window.location.href = '/appointments/success';
    }
  }
</script>
```

### Prompt for Claude Code

```
Act as Frontend/UX Lead using the frontend-design skill.

Create distinctive, production-grade healthcare booking interface:

1. Design System (using frontend-design):
   - Bold aesthetic direction (modern, clean, trustworthy)
   - Typography (distinctive fonts, not generic)
   - Color palette (calming for medical, clear CTAs)
   - Spacing & layout (generous, accessible)
   - Components (buttons, forms, cards, modals)

2. Critical Views:
   - Doctor dashboard (view schedule, manage appointments)
   - Patient booking flow (select time, enter info, pay)
   - Appointment confirmation (both sides)
   - Cancellation confirmation (with refund info)
   - Payment failure recovery

3. Real-time Features:
   - Appointment status updates (Turbo)
   - Notification badges (new messages/reminders)
   - Availability updates (when doctor goes offline)

4. Accessibility:
   - WCAG 2.1 AA compliance
   - Screen reader friendly
   - Keyboard navigation
   - Color contrast on all text
   - Form labels & error messages

5. Mobile Optimization:
   - Mobile-first design
   - Touch-friendly buttons (min 44x44px)
   - One-hand operation (bottom navigation)

6. Payment UX:
   - Stripe Elements (PCI-DSS compliant)
   - Clear payment flow
   - Confirmation before charging
   - Error messages (no sensitive data)
   - Invoice generation & download

Healthcare industry: Doctolib-like
Users: Doctors & Patients
Critical moments: Booking, payment, cancellation
```

---

## Role 4: Security Expert (CRITICAL)

**Duration**: 3 hours
**Focus**: OWASP, PCI-DSS, HIPAA, GDPR

### Premium Checklist

```
AUTHENTICATION (Required):
✅ Devise with secure password hashing (bcrypt)
✅ 2FA/MFA for accounts with sensitive access
✅ Session timeout (30 minutes)
✅ Secure password reset flow

AUTHORIZATION (Required):
✅ Pundit policies for all resources
✅ Row-level security (patient can only see their own data)
✅ Doctor can only access their schedule
✅ Admin controls audited

PAYMENT SECURITY (Critical - PCI-DSS):
✅ NEVER store raw credit cards
✅ Use Stripe (PCI-DSS Level 1)
✅ Idempotency keys to prevent double-charging
✅ Webhook validation for payment confirmations
✅ Refund safety (can only refund original card)

DATA PROTECTION (HIPAA/GDPR):
✅ Sensitive data encrypted (AES-256 at rest)
✅ TLS 1.3 for all traffic
✅ Data at rest: postgres encryption
✅ Audit logging for all sensitive access
✅ Right to deletion (GDPR compliance)
✅ Data export (GDPR compliance)

OWASP TOP 10:
✅ SQL Injection: Parameterized queries (Rails default)
✅ XSS: Content-Security-Policy header
✅ CSRF: Token protection (Rails default)
✅ Deserialization: Safe YAML/JSON
✅ Broken Auth: Devise + 2FA
✅ Sensitive Data: Encryption + audit logging
✅ XXE: Safe XML parsing (Nokogiri)
✅ Broken Access: Pundit authorization
✅ Dependency Vuln: Bundler audit weekly
✅ Insufficient Logging: Audit logging on all sensitive actions

SECURITY HEADERS:
✅ Content-Security-Policy: Strict
✅ X-Frame-Options: DENY
✅ X-Content-Type-Options: nosniff
✅ Strict-Transport-Security: HTTPS only
✅ Referrer-Policy: strict-origin-when-cross-origin
✅ Permissions-Policy: Restrict camera/microphone

RATE LIMITING:
✅ Login: 5 failed attempts / 15 minutes
✅ Password reset: 3 attempts / 1 hour
✅ Appointment booking: 10 / minute per user
✅ Payment API: 100 / minute per user
✅ General API: 1000 / hour per user

INCIDENT RESPONSE:
✅ Breach notification plan (24 hours)
✅ Data retention policy (auto-delete old records)
✅ Disaster recovery (test quarterly)
✅ Security audit (annual)
```

### Key Security Code

```ruby
# config/initializers/rack_attack.rb
class Rack::Attack
  # Limit login attempts
  throttle('logins/ip', limit: 5, period: 15.minutes) do |req|
    req.ip if req.path == '/users/sign_in' && req.post?
  end
  
  # Limit password reset
  throttle('password-reset/email', limit: 3, period: 1.hour) do |req|
    req.params['user']['email'] if req.path == '/password-resets' && req.post?
  end
  
  # Limit appointment booking
  throttle('appointments/user', limit: 10, period: 1.minute) do |req|
    req.user_id if req.path =~ /\/appointments/ && req.post?
  end
end

# app/policies/appointment_policy.rb
class AppointmentPolicy < ApplicationPolicy
  def show?
    user == record.doctor || user == record.patient || user.admin?
  end
  
  def create?
    user == record.patient && !user.doctor?
  end
  
  def cancel?
    (user == record.doctor || user == record.patient) && 
    record.pending? || record.confirmed?
  end
end

# Audit logging on sensitive actions
class AppointmentsController < ApplicationController
  def cancel
    @appointment.update(status: :cancelled)
    
    AuditLog.create(
      user: current_user,
      resource: 'Appointment',
      action: 'cancelled',
      resource_id: @appointment.id,
      ip_address: request.remote_ip,
      user_agent: request.user_agent,
      details: { cancellation_reason: params[:reason] }
    )
    
    ProcessRefundJob.perform_later(@appointment.payment.id)
  end
end
```

### Prompt for Claude Code

```
Act as Security Expert with penetration testing mindset.

Implement comprehensive security for healthcare booking system:

1. Authentication (Devise):
   - Secure password requirements (12+ chars, uppercase, special)
   - 2FA/MFA for admin & sensitive accounts
   - Session timeout (30 minutes)
   - Secure password reset flow

2. Authorization (Pundit):
   - Policies for User, Appointment, Payment
   - Row-level security (patient only sees own data)
   - Doctor access control (own schedule only)
   - Admin controls with audit trail

3. Payment Security (Stripe):
   - PCI-DSS Level 1 compliance
   - NO raw card storage
   - Idempotency keys for payments
   - Webhook validation
   - Refund safety

4. Data Encryption:
   - Sensitive fields encrypted at DB level (phone, SSN)
   - TLS 1.3 for all traffic
   - Encryption key rotation process

5. OWASP Prevention:
   - All 10 OWASP vulnerabilities covered
   - Penetration testing checklist
   - Vulnerability scanning (weekly)

6. Rate Limiting (Rack-Attack):
   - Login attempts: 5/15min per IP
   - Password reset: 3/1h per email
   - API endpoints: Based on criticality

7. Audit Logging:
   - Every sensitive action logged
   - Who, what, when, where (IP, user-agent)
   - Retention: 7 years (compliance)

8. Compliance:
   - GDPR: Data export, deletion, privacy
   - HIPAA: Healthcare data protection
   - PCI-DSS: Payment safety

Application: Healthcare booking with payments
Sensitive data: Appointments, medical history, payments
Compliance: GDPR, HIPAA, PCI-DSS
Threat model: Included in SECURITY.md
```

---

## Role 5: DevOps Engineer

**Duration**: 3 hours
**Focus**: Reliability, redundancy, disaster recovery

### Premium Requirements

```
Database:
✅ Master-replica replication (real-time sync)
✅ Hourly snapshots (automated)
✅ Point-in-time recovery (tested)
✅ Replication lag monitoring (< 1 second)

Backup:
✅ Daily cross-region backup
✅ Monthly test restore (to ensure it works)
✅ 30-day retention
✅ Encrypted backups

Deployment:
✅ Blue-green deployments (zero-downtime)
✅ Canary deployments (5% traffic, 1 hour monitoring)
✅ Automated rollback (on error spike)
✅ Health checks every 10 seconds

Monitoring:
✅ < 5 minute detection of issues
✅ PagerDuty integration (cannot ignore)
✅ Uptime monitoring (external + internal)
✅ Performance monitoring (response time, errors)

Scaling:
✅ Auto-scaling groups (based on CPU/load)
✅ Load balancing with health checks
✅ Database connection pooling (PgBouncer)
✅ CDN for static assets

Disaster Recovery:
✅ RTO < 30 minutes
✅ RPO < 5 minutes
✅ Tested recovery procedures
✅ Runbooks for common failures
```

---

## Role 6: QA Lead / Test Architect (CRITICAL)

**Duration**: 5 hours
**Focus**: 90%+ coverage, especially critical paths

### Coverage Breakdown (90%+)

```
CRITICAL TESTS (Must be 95%+):
├─ Authentication flow (login, 2FA, logout)
├─ Appointment creation (availability check, locking)
├─ Appointment cancellation (refund processing)
├─ Payment processing (Stripe integration, failure handling)
├─ Patient data access (authorization, audit logging)
└─ Doctor schedule access (role-based access)

IMPORTANT TESTS (Must be 90%+):
├─ All API endpoints (success + error cases)
├─ Form validations (client + server)
├─ Error handling (4xx, 5xx responses)
├─ Notification sending (SMS, email)
├─ Notification delivery (retry logic)
└─ Report generation

SUPPORTING TESTS (Must be 85%+):
├─ Background jobs (Sidekiq)
├─ Mailers (content, delivery)
├─ Decorators (presentation logic)
└─ Utility methods
```

### Test Examples

```ruby
# spec/models/appointment_spec.rb
describe Appointment do
  describe 'validations' do
    it { should validate_presence_of(:start_time) }
    it { should validate_presence_of(:end_time) }
    
    context 'when end_time <= start_time' do
      it 'is invalid' do
        appointment = build(:appointment, start_time: Time.now, end_time: 1.hour.ago)
        expect(appointment).not_to be_valid
        expect(appointment.errors[:end_time]).to include("must be after start time")
      end
    end
  end
  
  describe 'no_double_booking' do
    context 'when doctor already has appointment at that time' do
      let(:doctor) { create(:doctor) }
      let(:time) { 1.day.from_now.beginning_of_hour }
      
      before do
        create(:appointment, doctor: doctor, start_time: time, end_time: time + 1.hour)
      end
      
      it 'is invalid' do
        appointment = build(:appointment, doctor: doctor, start_time: time, end_time: time + 1.hour)
        expect(appointment).not_to be_valid
        expect(appointment.errors[:base]).to include("Doctor not available at this time")
      end
    end
  end
end

# spec/requests/appointments_spec.rb
describe 'POST /api/v1/appointments' do
  context 'when patient books appointment' do
    let(:patient) { create(:patient) }
    let(:doctor) { create(:doctor) }
    let(:params) do
      {
        doctor_id: doctor.id,
        start_time: 1.day.from_now,
        end_time: 1.day.from_now + 1.hour,
        cost: 50
      }
    end
    
    it 'creates appointment and payment' do
      post '/api/v1/appointments', params: params, headers: auth_headers(patient)
      expect(response).to have_http_status(:created)
      expect(Appointment.count).to eq(1)
      expect(Payment.count).to eq(1)
    end
    
    it 'sends confirmation notification' do
      expect {
        post '/api/v1/appointments', params: params, headers: auth_headers(patient)
      }.to have_enqueued_job(SendAppointmentConfirmationJob)
    end
    
    it 'prevents double-booking' do
      create(:appointment, doctor: doctor, start_time: params[:start_time], end_time: params[:end_time])
      
      post '/api/v1/appointments', params: params, headers: auth_headers(patient)
      expect(response).to have_http_status(:unprocessable_entity)
    end
  end
  
  context 'when payment fails' do
    it 'returns error and does not create appointment' do
      allow(Stripe::PaymentIntent).to receive(:create).and_raise(Stripe::CardError.new('Card declined', 'card_declined'))
      
      post '/api/v1/appointments', params: params, headers: auth_headers(patient)
      expect(response).to have_http_status(:unprocessable_entity)
      expect(Appointment.count).to eq(0)
    end
  end
end

# spec/services/appointment_service_spec.rb
describe AppointmentService do
  let(:doctor) { create(:doctor) }
  let(:patient) { create(:patient) }
  
  describe '#book_appointment' do
    context 'with valid parameters' do
      it 'books appointment and creates payment' do
        service = AppointmentService.new(
          doctor: doctor,
          patient: patient,
          start_time: 1.day.from_now,
          end_time: 1.day.from_now + 1.hour,
          cost: 50
        )
        
        expect {
          service.book_appointment
        }.to change(Appointment, :count).by(1).and change(Payment, :count).by(1)
      end
    end
    
    context 'when double-booking would occur' do
      before do
        create(:appointment, doctor: doctor, start_time: 1.day.from_now, end_time: 1.day.from_now + 1.hour)
      end
      
      it 'returns false and does not create appointment' do
        service = AppointmentService.new(
          doctor: doctor,
          patient: patient,
          start_time: 1.day.from_now,
          end_time: 1.day.from_now + 1.hour,
          cost: 50
        )
        
        expect(service.book_appointment).to be false
        expect(service.errors).to include("Doctor not available at this time")
      end
    end
  end
end
```

### Prompt for Claude Code

```
Act as QA Lead ensuring 90%+ test coverage for healthcare system.

Create comprehensive test suite:

1. Unit Tests (Models):
   - Validations for all models
   - Associations
   - Scopes and methods
   - Callbacks
   - Target: 95%+ for User, Appointment, Payment

2. Service Tests:
   - AppointmentService: book, cancel, reschedule
   - PaymentService: charge, refund, retry
   - NotificationService: send, log, retry
   - RefundService: process, validate

3. Integration Tests (API):
   - POST /appointments (success, failure, double-booking)
   - PATCH /appointments/:id (cancel, reschedule)
   - POST /payments (charge card, handle failures)
   - GET /appointments (authorization, filtering)
   - All error cases (4xx, 5xx)

4. System Tests (Capybara):
   - Patient books appointment (full workflow)
   - Doctor views schedule
   - Payment processing (Stripe mock)
   - Appointment cancellation with refund
   - 2FA login flow

5. Performance Tests:
   - 1000 concurrent appointment bookings
   - Payment processing under load
   - Database query optimization
   - API response times

6. Security Tests:
   - OWASP Top 10 coverage
   - Authorization (patient can't see others' data)
   - Rate limiting verification
   - SQL injection attempts
   - XSS payload testing

7. Mutation Testing:
   - Ensure tests actually catch bugs
   - Test quality validation

Test framework: RSpec
Factories: Factory Bot
Coverage target: 90%+ overall, 95%+ on critical
Coverage tool: SimpleCov
```

---

## Role 7: Database Architect

**Duration**: 2 hours
**Focus**: Replication, backups, optimization

### Premium Database Setup

```sql
-- Indexes on all critical queries
CREATE INDEX index_appointments_on_doctor_id ON appointments(doctor_id);
CREATE INDEX index_appointments_on_patient_id ON appointments(patient_id);
CREATE INDEX index_appointments_on_start_time ON appointments(start_time);
CREATE INDEX index_appointments_on_status ON appointments(status);

-- Composite index for frequent queries
CREATE INDEX index_appointments_on_doctor_and_time ON appointments(doctor_id, start_time, end_time);

-- Audit logging index
CREATE INDEX index_audit_logs_on_user_id ON audit_logs(user_id);
CREATE INDEX index_audit_logs_on_created_at ON audit_logs(created_at);
CREATE INDEX index_audit_logs_on_resource ON audit_logs(resource, resource_id);

-- Replication setup (PostgreSQL)
-- Master: Write operations
-- Replica: Read-only (for reporting, backups)

-- Backup automation
-- Hourly: WAL (Write-Ahead Logs)
-- Daily: Full snapshot
-- Cross-region replication
```

---

## Integration Checklist

Before deploying to production:

```
✅ All tests passing (100%)
✅ Coverage >90% (critical paths 95%+)
✅ Security audit passed
✅ Penetration testing checklist completed
✅ Load testing successful (1000+ concurrent users)
✅ Database replication verified (< 1 sec lag)
✅ Backup recovery tested (can restore successfully)
✅ Monitoring alerts configured
✅ Incident runbooks prepared
✅ GDPR/HIPAA compliance verified
✅ Payment processing tested (with test cards)
✅ Email/SMS notifications working
✅ Performance budgets met
✅ Accessibility testing passed (WCAG 2.1 AA)
✅ Code review completed
✅ Documentation complete
```

---

**Total Execution: 24 hours of senior expert time**

**Result: Production-ready healthcare booking system with 90%+ coverage, zero-defect standards, fully compliant with GDPR/HIPAA/PCI-DSS.**
