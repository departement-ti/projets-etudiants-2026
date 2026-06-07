package com.tmazzacademy.tmazzacademy.service;

import org.springframework.mail.SimpleMailMessage;
import org.springframework.mail.javamail.JavaMailSender;
import org.springframework.stereotype.Service;

@Service
public class EmailService {

    private final JavaMailSender mailSender;

    public EmailService(JavaMailSender mailSender) {
        this.mailSender = mailSender;
    }

    public void sendInstructorCredentials(String to, String password) {
        try {
            SimpleMailMessage message = new SimpleMailMessage();

            message.setTo(to);
            message.setSubject("Tmazz Academy Instructor Account Accepted");

            message.setText(
                    "Hello,\n\n" +
                    "Your instructor account has been accepted.\n\n" +
                    "Email: " + to + "\n" +
                    "Password: " + password + "\n\n" +
                    "You can now login to Tmazz Academy."
            );

            mailSender.send(message);
            System.out.println("EMAIL SENT TO: " + to);

        } catch (Exception e) {
            System.out.println("EMAIL ERROR: " + e.getMessage());
            e.printStackTrace();
        }
    }
    
    //Student
    public void sendStudentCredentials(String to, String password) {
        SimpleMailMessage message = new SimpleMailMessage();

        message.setTo(to);
        message.setSubject("Tmazz Academy Student Account Accepted");

        message.setText(
                "Hello,\n\n" +
                "Your student account has been accepted.\n\n" +
                "Email: " + to + "\n" +
                "Password: " + password + "\n\n" +
                "You can now login to Tmazz Academy."
        );

        mailSender.send(message);
    }
}