package com.recrutement.recrutement.repositories;

import com.recrutement.recrutement.entities.ConversationMessage;
import com.recrutement.recrutement.entities.User;
import java.util.Collection;
import java.util.List;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

@Repository
public interface ConversationMessageRepository extends JpaRepository<ConversationMessage, Long> {
    List<ConversationMessage> findByCandidature_IdOrderBySentAtAsc(Long candidatureId);

    List<ConversationMessage> findByCandidature_IdInOrderBySentAtDesc(Collection<Long> candidatureIds);

    List<ConversationMessage> findByCandidature_IdAndRecipient_IdAndLueFalseOrderBySentAtAsc(Long candidatureId, Long recipientId);

    long countByCandidature_IdAndRecipient_IdAndLueFalse(Long candidatureId, Long recipientId);

    @Modifying(flushAutomatically = true, clearAutomatically = true)
    @Query("delete from ConversationMessage cm where cm.candidature.id in :candidatureIds")
    void deleteAllByCandidatureIds(@Param("candidatureIds") Collection<Long> candidatureIds);

    @Modifying(flushAutomatically = true, clearAutomatically = true)
    @Query("delete from ConversationMessage cm where cm.sender.id = :userId or cm.recipient.id = :userId")
    void deleteAllByUserId(@Param("userId") Long userId);
}
