package com.recrutement.recrutement.service;

import com.cloudinary.Cloudinary;
import com.cloudinary.utils.ObjectUtils;
import java.io.IOException;
import java.util.HashMap;
import java.util.Map;
import org.springframework.stereotype.Service;
import org.springframework.web.multipart.MultipartFile;

@Service
public class CloudinaryStorageService {
    private final Cloudinary cloudinary;

    public CloudinaryStorageService(Cloudinary cloudinary) {
        this.cloudinary = cloudinary;
    }

    public UploadedAsset uploadCandidateImage(Long candidateId, MultipartFile file, String assetType) {
        return upload(candidateId, file, assetType, "image");
    }

    public UploadedAsset uploadCandidateDocument(Long candidateId, MultipartFile file, String assetType) {
        return upload(candidateId, file, assetType, "raw");
    }

    public void deleteQuietly(String publicId, String resourceType) {
        if (publicId == null || publicId.isBlank()) {
            return;
        }

        try {
            cloudinary.uploader().destroy(publicId, ObjectUtils.asMap(
                    "resource_type", resourceType,
                    "invalidate", true
            ));
        } catch (Exception ignored) {
            // Best effort cleanup to avoid blocking profile save.
        }
    }

    private UploadedAsset upload(Long candidateId, MultipartFile file, String assetType, String resourceType) {
        try {
            Map<String, Object> options = new HashMap<>();
            options.put("folder", "smart-recruit/candidates/" + candidateId + "/" + assetType);
            options.put("resource_type", resourceType);
            options.put("use_filename", true);
            options.put("unique_filename", true);
            options.put("overwrite", true);

            Map<?, ?> result = cloudinary.uploader().upload(file.getBytes(), options);

            Object secureUrl = result.get("secure_url");
            Object publicId = result.get("public_id");

            return new UploadedAsset(
                    secureUrl == null ? "" : String.valueOf(secureUrl),
                    publicId == null ? "" : String.valueOf(publicId),
                    safeFileName(file)
            );
        } catch (IOException ex) {
            throw new RuntimeException("Lecture du fichier impossible avant l'envoi vers Cloudinary.");
        } catch (Exception ex) {
            throw new RuntimeException("Envoi du fichier vers Cloudinary impossible.");
        }
    }

    private String safeFileName(MultipartFile file) {
        String originalName = file.getOriginalFilename();
        return originalName == null || originalName.isBlank() ? "fichier" : originalName.trim();
    }

    public static final class UploadedAsset {
        private final String secureUrl;
        private final String publicId;
        private final String originalFileName;

        public UploadedAsset(String secureUrl, String publicId, String originalFileName) {
            this.secureUrl = secureUrl;
            this.publicId = publicId;
            this.originalFileName = originalFileName;
        }

        public String getSecureUrl() {
            return secureUrl;
        }

        public String getPublicId() {
            return publicId;
        }

        public String getOriginalFileName() {
            return originalFileName;
        }
    }
}
