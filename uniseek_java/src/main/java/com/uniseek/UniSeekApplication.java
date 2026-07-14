package com.uniseek;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.scheduling.annotation.EnableScheduling;

@SpringBootApplication
@EnableScheduling
public class UniSeekApplication {
    public static void main(String[] args) {
        SpringApplication.run(UniSeekApplication.class, args);
    }
}