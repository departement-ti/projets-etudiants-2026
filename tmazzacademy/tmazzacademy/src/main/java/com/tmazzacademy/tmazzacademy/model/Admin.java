package com.tmazzacademy.tmazzacademy.model;

import jakarta.persistence.DiscriminatorValue;
import jakarta.persistence.Entity;

@Entity
@DiscriminatorValue("ADMIN")
public class Admin extends User {

	public Admin() {}

	public Admin(String name, String lastname, String email, String password, String tel, Role role) {
		super(name, lastname, email, password, tel, role);
	}
	
	

	

}
