package com.recrutement.recrutement.service;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.databind.node.ObjectNode;
import java.io.IOException;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.util.List;
import java.util.concurrent.TimeUnit;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;

@Service
public class PythonGroqAgentService {
    private static final Logger log = LoggerFactory.getLogger(PythonGroqAgentService.class);

    private final ObjectMapper objectMapper;

    @Value("${assistant.python.command:py}")
    private String pythonCommand;

    @Value("${assistant.python.script-path:IA/smart_recruit_ai_agent.py}")
    private String scriptPath;

    @Value("${groq.api.key:}")
    private String groqApiKey;

    @Value("${groq.api.base-url:https://api.groq.com/openai/v1}")
    private String groqApiBaseUrl;

    @Value("${groq.api.model:llama-3.3-70b-versatile}")
    private String groqModel;

    public PythonGroqAgentService(ObjectMapper objectMapper) {
        this.objectMapper = objectMapper;
    }

    public JsonNode invoke(String action, Object payload) {
        assertGroqConfigured(action);
        Path resolvedScript = resolveScriptPath();

        log.info(
                "Agent IA: lancement Groq via script Python. action={}, script={}, model={}, baseUrl={}",
                action,
                resolvedScript,
                safe(groqModel),
                safe(groqApiBaseUrl)
        );

        ProcessBuilder processBuilder = new ProcessBuilder(pythonCommand, resolvedScript.toString());
        processBuilder.redirectErrorStream(true);

        processBuilder.environment().putIfAbsent("PYTHONIOENCODING", "utf-8");
        processBuilder.environment().put("GROQ_API_KEY", safe(groqApiKey));
        processBuilder.environment().put("GROQ_BASE_URL", safe(groqApiBaseUrl));
        processBuilder.environment().put("GROQ_MODEL", safe(groqModel));

        ObjectNode requestNode = objectMapper.createObjectNode();
        requestNode.put("action", safe(action));
        requestNode.set("payload", objectMapper.valueToTree(payload));

        try {
            Process process = processBuilder.start();
            process.getOutputStream().write(objectMapper.writeValueAsBytes(requestNode));
            process.getOutputStream().flush();
            process.getOutputStream().close();

            boolean finished = process.waitFor(60, TimeUnit.SECONDS);
            if (!finished) {
                process.destroyForcibly();
                log.error("Agent IA: delai depasse pour Groq. action={}", action);
                throw new RuntimeException("L'agent IA Groq a depasse le temps maximal de reponse.");
            }

            String rawOutput = new String(process.getInputStream().readAllBytes(), StandardCharsets.UTF_8).trim();
            if (process.exitValue() != 0) {
                log.error(
                        "Agent IA: echec du script Python. action={}, exitCode={}, output={}",
                        action,
                        process.exitValue(),
                        rawOutput
                );
                throw new RuntimeException(
                        rawOutput.isBlank()
                                ? "Le script Python de l'agent IA Groq a echoue."
                                : rawOutput
                );
            }

            JsonNode response;
            try {
                response = objectMapper.readTree(rawOutput);
            } catch (IOException ex) {
                log.error("Agent IA: reponse JSON invalide. action={}, output={}", action, rawOutput);
                throw new RuntimeException("Reponse invalide du script Python Groq.");
            }

            if (!response.path("success").asBoolean(true)) {
                String errorMessage = safe(response.path("message").asText());
                log.warn("Agent IA: appel Groq en echec. action={}, message={}", action, errorMessage);
                throw new RuntimeException(
                        errorMessage.isBlank() ? "Agent IA Groq indisponible." : errorMessage
                );
            }

            log.info("Agent IA: reponse Groq recue avec succes. action={}", action);
            return response;
        } catch (IOException ex) {
            log.error("Agent IA: impossible de lancer Python. action={}, erreur={}", action, ex.getMessage());
            throw new RuntimeException("Impossible de lancer le script Python de l'agent IA.");
        } catch (InterruptedException ex) {
            Thread.currentThread().interrupt();
            log.error("Agent IA: execution interrompue. action={}", action);
            throw new RuntimeException("L'execution du script Python de l'agent IA a ete interrompue.");
        }
    }

    public boolean isConfigured() {
        return !safe(groqApiKey).isBlank()
                && !safe(groqApiBaseUrl).isBlank()
                && !safe(groqModel).isBlank();
    }

    private void assertGroqConfigured(String action) {
        if (safe(groqApiKey).isBlank()) {
            log.warn("Agent IA: GROQ_API_KEY absente. action={}", action);
            throw new RuntimeException(
                    "La cle API Groq est absente sur le backend. Configurez GROQ_API_KEY "
                            + "ou ajoutez assistant.groq.api.key dans StagePfeBackend/assistant-secrets.properties, "
                            + "puis redemarrez le backend."
            );
        }
        if (safe(groqApiBaseUrl).isBlank()) {
            log.warn("Agent IA: groq.api.base-url absent. action={}", action);
            throw new RuntimeException("La configuration Groq du backend est incomplete. Le base URL Groq est absent.");
        }
        if (safe(groqModel).isBlank()) {
            log.warn("Agent IA: groq.api.model absent. action={}", action);
            throw new RuntimeException("La configuration Groq du backend est incomplete. Le modele Groq est absent.");
        }
    }

    private Path resolveScriptPath() {
        Path configured = Paths.get(scriptPath);
        Path backendDir = Paths.get(System.getProperty("user.dir"));

        List<Path> candidates = List.of(
                configured.isAbsolute() ? configured : backendDir.resolve(configured).normalize(),
                backendDir.resolve("IA").resolve("smart_recruit_ai_agent.py").normalize(),
                backendDir.resolve("..").resolve("StagePfeBackend").resolve("IA").resolve("smart_recruit_ai_agent.py").normalize()
        );

        return candidates.stream()
                .filter(Files::exists)
                .findFirst()
                .orElseThrow(() -> new RuntimeException(
                        "Le script Python de l'agent IA est introuvable. Verifiez assistant.python.script-path."
                ));
    }

    private String safe(String value) {
        return value == null ? "" : value.trim();
    }
}
