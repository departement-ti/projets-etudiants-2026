package com.rayhan.erp.repository;

import com.rayhan.erp.model.User;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface UserRepository extends JpaRepository<User, Long> {
    Optional<User> findByUsername(String username);
    Boolean existsByUsername(String username);
    Boolean existsByEmail(String email);
    Optional<User> findByClient_Id(Long clientId);

    @Query("SELECT u FROM User u WHERE u.client IS NULL")
    List<User> findAllStaff();

    @Query("SELECT u FROM User u JOIN u.roles r WHERE r.name = :role")
    List<User> findByRole(com.rayhan.erp.model.ERole role);
}
