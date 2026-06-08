package com.rayhan.erp.repository;

import com.rayhan.erp.model.Client;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface ClientRepository extends JpaRepository<Client, Long> {
    List<Client> findByActifTrue();
    List<Client> findByRaisonSocialeContainingIgnoreCase(String search);
}
