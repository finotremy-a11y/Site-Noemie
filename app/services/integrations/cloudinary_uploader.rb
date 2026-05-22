module Integrations
  class CloudinaryUploader
    def upload(file_path:, folder: "products")
      Cloudinary::Uploader.upload(file_path, folder: folder)
    end
  end
end
