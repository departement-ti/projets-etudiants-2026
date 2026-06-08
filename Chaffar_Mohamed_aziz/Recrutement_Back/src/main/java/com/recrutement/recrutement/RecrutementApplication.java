package com.recrutement.recrutement;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.scheduling.annotation.EnableScheduling;

@SpringBootApplication
@EnableScheduling
public class RecrutementApplication {

    public static void main(String[] args) {
        SpringApplication.run(RecrutementApplication.class, args);
    }

}
