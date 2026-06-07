package com.tmazzacademy.tmazzacademy.model;

import java.util.List;

import com.fasterxml.jackson.annotation.JsonManagedReference;

import jakarta.persistence.Column;
import jakarta.persistence.DiscriminatorValue;
import jakarta.persistence.Entity;
import jakarta.persistence.OneToMany;

@Entity
@DiscriminatorValue("INSTRUCTOR")
public class Instructor extends User {

	@Column(name = "speciality")
    private String speciality;

    /*@OneToMany(mappedBy = "instructor")
    @JsonManagedReference
    private List<Student> studentList;
    @OneToMany Cours */
    
    public Instructor() {}

    public Instructor(String name, String lastname, String email,
                      String password, String tel, Role role,
                      String speciality) {
        super(name, lastname, email, password, tel, role);
        this.speciality = speciality;
    }

    // GETTERS & SETTERS

    public String getSpeciality() {
        return speciality;
    }

    public void setSpeciality(String speciality) {
        this.speciality = speciality;
    }

  
}