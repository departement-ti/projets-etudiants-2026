package com.recrutement.recrutement.config;

import java.util.List;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.boot.ApplicationRunner;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.jdbc.core.JdbcTemplate;

@Slf4j
@Configuration
@RequiredArgsConstructor
public class AiTestSchemaUpdater {

    private final JdbcTemplate jdbcTemplate;

    @Bean
    public ApplicationRunner updateAiTestForeignKeys() {
        return args -> {
            addColumnIfMissing("ai_test", "title", "TEXT");
            addColumnIfMissing("ai_test", "description", "TEXT");
            addColumnIfMissing("ai_test", "number_of_questions", "INTEGER");
            addColumnIfMissing("ai_test", "passing_score", "DOUBLE PRECISION");
            addColumnIfMissing("ai_test", "total_duration_seconds", "INTEGER");
            addColumnIfMissing("ai_test", "difficulty", "VARCHAR(64)");
            addColumnIfMissing("ai_test", "allow_previous_question", "BOOLEAN");
            addColumnIfMissing("ai_test", "evaluation_skills_json", "TEXT");
            addColumnIfMissing("ai_test", "updated_at", "TIMESTAMP");

            addColumnIfMissing("ai_question", "order_index", "INTEGER");
            addColumnIfMissing("ai_question", "time_limit_seconds", "INTEGER");
            addColumnIfMissing("ai_question", "accepted_by_recruiter", "BOOLEAN");
            addColumnIfMissing("ai_question", "created_at", "TIMESTAMP");
            addColumnIfMissing("ai_question", "updated_at", "TIMESTAMP");

            addColumnIfMissing("ai_answer", "ai_test_result_id", "BIGINT");
            addColumnIfMissing("ai_answer", "answered_at", "TIMESTAMP");
            addColumnIfMissing("ai_answer", "time_spent_seconds", "INTEGER");

            addColumnIfMissing("ai_test_result", "application_id", "BIGINT");
            addColumnIfMissing("ai_test_result", "candidate_id", "BIGINT");
            addColumnIfMissing("ai_test_result", "started_at", "TIMESTAMP");
            addColumnIfMissing("ai_test_result", "submitted_at", "TIMESTAMP");
            addColumnIfMissing("ai_test_result", "created_at", "TIMESTAMP");
            addColumnIfMissing("ai_test_result", "updated_at", "TIMESTAMP");
            addColumnIfMissing("ai_test_result", "current_question_started_at", "TIMESTAMP");
            addColumnIfMissing("ai_test_result", "current_question_expires_at", "TIMESTAMP");
            addColumnIfMissing("ai_test_result", "current_question_index", "INTEGER");
            addColumnIfMissing("ai_test_result", "score", "DOUBLE PRECISION");
            addColumnIfMissing("ai_test_result", "status", "VARCHAR(64)");
            addColumnIfMissing("ai_test_result", "closed_reason", "TEXT");

            replaceForeignKeyWithCascade(
                    "ai_answer",
                    "ai_test_id",
                    "ai_test",
                    "id",
                    "fk_ai_answer_ai_test_cascade"
            );
            replaceForeignKeyWithCascade(
                    "ai_answer",
                    "question_id",
                    "ai_question",
                    "id",
                    "fk_ai_answer_question_cascade"
            );
            replaceForeignKeyWithCascade(
                    "ai_question",
                    "ai_test_id",
                    "ai_test",
                    "id",
                    "fk_ai_question_ai_test_cascade"
            );
            replaceForeignKeyWithCascade(
                    "ai_test_result",
                    "ai_test_id",
                    "ai_test",
                    "id",
                    "fk_ai_test_result_ai_test_cascade"
            );
            replaceForeignKeyWithCascade(
                    "ai_answer",
                    "ai_test_result_id",
                    "ai_test_result",
                    "id",
                    "fk_ai_answer_ai_test_result_cascade"
            );
            replaceForeignKeyWithCascade(
                    "ai_test_result",
                    "application_id",
                    "candidature",
                    "id",
                    "fk_ai_test_result_application_cascade"
            );
            replaceForeignKeyWithCascade(
                    "ai_test_result",
                    "candidate_id",
                    "candidate",
                    "id",
                    "fk_ai_test_result_candidate_cascade"
            );
        };
    }

    private void addColumnIfMissing(String tableName, String columnName, String sqlType) {
        runSql("ALTER TABLE " + tableName + " ADD COLUMN IF NOT EXISTS " + columnName + " " + sqlType);
    }

    private void replaceForeignKeyWithCascade(
            String tableName,
            String columnName,
            String referencedTable,
            String referencedColumn,
            String targetConstraintName
    ) {
        try {
            List<String> existingConstraints = jdbcTemplate.queryForList(
                    """
                    select tc.constraint_name
                    from information_schema.table_constraints tc
                    join information_schema.key_column_usage kcu
                      on tc.constraint_name = kcu.constraint_name
                     and tc.table_schema = kcu.table_schema
                    where tc.constraint_type = 'FOREIGN KEY'
                      and tc.table_schema = 'public'
                      and tc.table_name = ?
                      and kcu.column_name = ?
                    """,
                    String.class,
                    tableName,
                    columnName
            );

            for (String constraintName : existingConstraints) {
                runSql("ALTER TABLE " + tableName + " DROP CONSTRAINT IF EXISTS " + constraintName);
            }

            runSql(
                    "ALTER TABLE " + tableName
                            + " ADD CONSTRAINT " + targetConstraintName
                            + " FOREIGN KEY (" + columnName + ") REFERENCES "
                            + referencedTable + "(" + referencedColumn + ") ON DELETE CASCADE"
            );
        } catch (Exception ex) {
            log.debug(
                    "Schema update skipped for FK {}.{} -> {}({}): {}",
                    tableName,
                    columnName,
                    referencedTable,
                    referencedColumn,
                    ex.getMessage()
            );
        }
    }

    private void runSql(String sql) {
        try {
            jdbcTemplate.execute(sql);
        } catch (Exception ex) {
            log.debug("Schema update skipped for SQL [{}]: {}", sql, ex.getMessage());
        }
    }
}
