package com.recrutement.recrutement.repositories;

import com.recrutement.recrutement.entities.Role;
import com.recrutement.recrutement.entities.User;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface UserRepository extends JpaRepository<User,Long> {
    Optional<User> findByEmail(String email);

    boolean existsByEmail(String email);

    Optional<User> findByactivationToken(String token);

    Optional<User> findByResetPasswordToken(String token);

    List<User> findAllByRole(Role role);

    List<User> findByNomContainingIgnoreCaseOrEmailContainingIgnoreCase(String nom, String email);

}
