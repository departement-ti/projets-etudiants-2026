package com.recrutement.recrutement.config;

import com.cloudinary.Cloudinary;
import com.cloudinary.utils.ObjectUtils;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

@Configuration
public class CloudinaryConfig {

    @Bean
    public Cloudinary cloudinary() {
        return new Cloudinary(ObjectUtils.asMap(
                "cloud_name", "dec9nw2p7",
                "api_key", "286161152951464",
                "api_secret", "Jd1ii17nmYQCe2Xuu9E1YrevNCY"
        ));
    }
}
