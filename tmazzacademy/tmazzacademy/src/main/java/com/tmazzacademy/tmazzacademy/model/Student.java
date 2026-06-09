package com.tmazzacademy.tmazzacademy.model;


import jakarta.persistence.DiscriminatorValue;
import jakarta.persistence.Entity;

@Entity
@DiscriminatorValue("STUDENT")
public class Student extends User {

  
   

    public Student() {}

    public Student(String name, String lastname, String email,
                   String password, String tel, Role role, Instructor instructor) {
        super(name, lastname, email, password, tel, role);
    }

    
}