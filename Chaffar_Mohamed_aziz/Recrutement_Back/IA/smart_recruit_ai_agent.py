import json
import os
import re
import sys
import urllib.error
import urllib.request


class AssistantError(Exception):
    pass


def safe_text(value):
    return str(value or "").strip()


def get_env_or_fail(name, human_label):
    value = safe_text(os.getenv(name))
    if not value:
        raise AssistantError(f"{human_label} absente. Configurez la variable d'environnement {name} sur le backend.")
    return value


def normalized_base_url():
    base_url = safe_text(os.getenv("GROQ_BASE_URL")) or "https://api.groq.com/openai/v1"
    return base_url.rstrip("/")


def current_model():
    return safe_text(os.getenv("GROQ_MODEL")) or "llama-3.3-70b-versatile"


def extract_json_object(text):
    cleaned = safe_text(text)
    if not cleaned:
        return None

    try:
        return json.loads(cleaned)
    except json.JSONDecodeError:
        pass

    match = re.search(r"\{.*\}", cleaned, re.DOTALL)
    if not match:
        return None

    try:
        return json.loads(match.group(0))
    except json.JSONDecodeError:
        return None


def parse_groq_error_body(raw_body):
    message = safe_text(raw_body)
    if not message:
        return ""

    try:
        body = json.loads(message)
    except json.JSONDecodeError:
        return message

    error = body.get("error")
    if isinstance(error, dict):
        return safe_text(error.get("message")) or safe_text(error.get("type")) or message
    if isinstance(error, str):
        return error
    return safe_text(body.get("message")) or message


def normalize_error_detail(detail):
    cleaned = safe_text(detail)
    if not cleaned:
        return ""

    lowered = cleaned.lower()
    if "error code: 1010" in lowered or "1010" == cleaned:
        return (
            "Groq a bloque la requete avant traitement (code 1010). "
            "Cela correspond en general a un blocage de securite cote reseau/client, "
            "pas a une erreur metier du backend."
        )
    return cleaned


def system_prompt():
    return (
        "Tu es l'agent IA Smart Recruit. "
        "Tu reponds uniquement avec un objet JSON valide, sans markdown, sans texte autour, sans commentaire. "
        "Sois professionnel, utile, precis et exploitable par une application SaaS de recrutement."
    )


def recruiter_offer_prompt(payload):
    return (
        "Genere une description d'offre professionnelle et concise. "
        "Retourne uniquement un JSON avec les cles message, generatedDescription, highlights, keywords. "
        "highlights doit etre un tableau de 3 elements maximum. keywords doit etre un tableau de mots-cles utiles. "
        "Donnees metier: "
        + json.dumps(payload, ensure_ascii=False)
    )


def interview_questions_prompt(payload):
    return (
        "Genere des questions d'entretien utiles et variees. "
        "Retourne uniquement un JSON avec les cles message, intro, questions. "
        "questions doit etre un tableau de questions concretes et actionnables. "
        "Donnees metier: "
        + json.dumps(payload, ensure_ascii=False)
    )


def company_description_prompt(payload):
    return (
        "Genere une description entreprise claire, professionnelle et attractive pour un profil employeur Smart Recruit. "
        "Retourne uniquement un JSON avec les cles message, generatedDescription, highlights. "
        "generatedDescription doit etre un texte de presentation fluide, credible et orienté marque employeur, en 2 ou 3 paragraphes courts maximum. "
        "highlights doit etre un tableau de 3 points maximum mettant en avant l'activite, l'environnement ou la valeur de l'entreprise. "
        "N'invente pas des informations trop specifiques qui ne sont pas presentes dans les donnees. "
        "Donnees metier: "
        + json.dumps(payload, ensure_ascii=False)
    )


def candidate_search_prompt(payload):
    return (
        "Analyse cette recherche recruteur et les profils candidats fournis. "
        "Retourne uniquement un JSON avec les cles message et suggestions. "
        "suggestions doit etre un tableau de candidats classes du plus pertinent au moins pertinent. "
        "Chaque suggestion doit contenir candidateId, name, email, jobTitle, location, experience, score, rationale, profileSummary, matchingSkills. "
        "score doit etre un nombre de 0 a 100. matchingSkills doit etre un tableau. "
        "N'invente pas de candidat en dehors de ceux fournis. "
        "Donnees metier: "
        + json.dumps(payload, ensure_ascii=False)
    )


def candidate_coach_prompt(payload):
    return (
        "Aide ce candidat a mieux valoriser son profil et ses candidatures. "
        "Retourne uniquement un JSON avec les cles message, content, suggestions. "
        "content doit etre une reponse claire, concrete, orientee action. suggestions doit etre un tableau de 3 pistes maximum. "
        "Donnees metier: "
        + json.dumps(payload, ensure_ascii=False)
    )


def assistant_chat_prompt(payload):
    role = safe_text(payload.get("role")).upper() or "GENERAL"
    context_type = safe_text(payload.get("contextType")).upper() or "GENERAL"
    if role == "RECRUITER":
        audience_instruction = (
            "Tu aides un recruteur Smart Recruit. "
            "Tu peux aider a generer ou ameliorer une offre, proposer des questions d'entretien, analyser un candidat, "
            "preparer un entretien, generer un email professionnel de refus et orienter une recherche de profils."
        )
    else:
        audience_instruction = (
            "Tu aides un candidat Smart Recruit. "
            "Tu peux aider a ameliorer un profil, choisir des competences, comprendre un score de matching, preparer un entretien "
            "et mieux presenter un CV ou une candidature."
        )

    return (
        audience_instruction
        + " Retourne uniquement un JSON avec les cles message, response, suggestions. "
        "message doit etre une phrase courte d'etat. response doit etre la vraie reponse, claire, utile et exploitable. "
        "suggestions doit contenir 2 a 4 pistes courtes ou prochaines actions. "
        "Ne revele aucune donnee sensible. "
        f"Contexte cible: {context_type}. "
        "Donnees metier: "
        + json.dumps(payload, ensure_ascii=False)
    )


def cv_autofill_prompt(payload):
    referential_skills = payload.get("referentialSkills", [])
    referential_text = ", ".join(referential_skills[:200])

    return (
        "Analyse le contenu de ce CV pour pre-remplir un profil candidat Smart Recruit. "
        "Retourne uniquement un JSON avec les cles suivantes : "
        "message, fullName, profession, email, phone, jobTitle, address, description, experiences, education, skills. "
        "Utilise une chaine vide si une information est absente et un tableau vide si une liste est absente. "
        "description doit resumer le profil en 2 ou 3 phrases maximum. "
        "experiences est un tableau d'objets {title, company, location, period, description}. "
        "education est un tableau d'objets {title, degree, institute, year}. "
        "skills est un tableau d'objets {title, level, yearsExperience, percentage}. "
        "level doit etre uniquement Debutant, Intermediaire, Avance ou Expert. "
        "percentage doit etre un entier entre 40 et 95. "
        "Si une competence ressemble a une competence du referentiel suivant, utilise de preference l'intitule du referentiel : "
        f"{referential_text}. "
        "N'invente pas d'experience ou de formation non presente dans le CV. "
        "Nom du fichier: "
        + json.dumps(payload.get("fileName", ""), ensure_ascii=False)
        + ". Texte du CV: "
        + json.dumps(payload.get("cvText", ""), ensure_ascii=False)
    )


def ai_test_generation_prompt(payload):
    return (
        "Genere un test de preselection technique et metier pour une plateforme de recrutement. "
        "Retourne uniquement un JSON avec les cles message et questions. "
        "questions doit etre un tableau de 4 a 6 objets avec les cles questionText, questionType, options, correctAnswer, expectedKeywords, points. "
        "questionType doit etre uniquement MCQ, SHORT_TEXT ou SCENARIO. "
        "Pour MCQ, fournis exactement 4 options et une correctAnswer identique a l une des options. "
        "Pour SHORT_TEXT et SCENARIO, laisse correctAnswer vide et fournis expectedKeywords comme tableau de mots ou expressions attendus. "
        "Distribue les points pour totaliser environ 100 points. "
        "Le test doit etre adapte au titre du poste, au niveau d experience, a la description et aux competences demandees. "
        "Donnees metier: "
        + json.dumps(payload, ensure_ascii=False)
    )


def ai_test_evaluation_prompt(payload):
    return (
        "Evalue un test de preselection candidat. "
        "Retourne uniquement un JSON avec les cles message, globalScore, strengths, weaknesses, generatedReport, answers. "
        "globalScore doit etre un nombre entre 0 et 100. "
        "strengths et weaknesses doivent etre des tableaux courts. "
        "generatedReport doit etre un texte professionnel concis avec score global, points forts, points faibles et recommandation. "
        "answers doit etre un tableau contenant pour chaque question les cles questionId, isCorrect, pointsObtained. "
        "pointsObtained doit respecter le bareme de chaque question. "
        "Pour les questions ouvertes, evalue la pertinence, la precision et l adequation au poste. "
        "Ne fournis aucune cle supplementaire en dehors de ce schema. "
        "Donnees metier: "
        + json.dumps(payload, ensure_ascii=False)
    )


def build_prompt(action, payload):
    if action == "generate_offer":
        return recruiter_offer_prompt(payload)
    if action == "generate_company_description":
        return company_description_prompt(payload)
    if action == "suggest_questions":
        return interview_questions_prompt(payload)
    if action == "find_candidates":
        return candidate_search_prompt(payload)
    if action == "candidate_coach":
        return candidate_coach_prompt(payload)
    if action == "assistant_chat":
        return assistant_chat_prompt(payload)
    if action == "cv_autofill":
        return cv_autofill_prompt(payload)
    if action == "generate_ai_test":
        return ai_test_generation_prompt(payload)
    if action == "evaluate_ai_test":
        return ai_test_evaluation_prompt(payload)
    raise AssistantError("Action IA inconnue.")


def call_groq(action, payload):
    api_key = get_env_or_fail("GROQ_API_KEY", "Cle API Groq")
    model = current_model()
    endpoint = f"{normalized_base_url()}/chat/completions"

    body = json.dumps(
        {
            "model": model,
            "temperature": 0.2,
            "response_format": {"type": "json_object"},
            "messages": [
                {"role": "system", "content": system_prompt()},
                {"role": "user", "content": build_prompt(action, payload)},
            ],
        }
    ).encode("utf-8")

    request = urllib.request.Request(
        url=endpoint,
        data=body,
        headers={
            "Content-Type": "application/json",
            "Authorization": f"Bearer {api_key}",
            "Accept": "application/json",
            "User-Agent": "SmartRecruit-GroqAgent/1.0",
        },
        method="POST",
    )

    try:
        with urllib.request.urlopen(request, timeout=60) as response:
            raw = response.read().decode("utf-8")
    except urllib.error.HTTPError as exc:
        raw_error = exc.read().decode("utf-8", errors="replace")
        detail = normalize_error_detail(parse_groq_error_body(raw_error))
        if exc.code in (401, 403):
            raise AssistantError(
                "Appel Groq impossible. La cle API Groq est invalide ou la requete a ete refusee."
                + (f" Detail: {detail}" if detail else "")
            ) from exc
        if exc.code == 429:
            raise AssistantError(
                "Appel Groq impossible. La limite Groq a ete atteinte ou le compte ne dispose pas de credits suffisants."
                + (f" Detail: {detail}" if detail else "")
            ) from exc
        raise AssistantError(
            f"Appel Groq impossible. Groq a retourne HTTP {exc.code}."
            + (f" Detail: {detail}" if detail else "")
        ) from exc
    except urllib.error.URLError as exc:
        raise AssistantError(
            f"Appel Groq impossible. Erreur reseau Groq: {safe_text(exc.reason) or 'connexion echouee.'}"
        ) from exc
    except TimeoutError as exc:
        raise AssistantError("Appel Groq impossible. Le delai de reponse Groq a ete depasse.") from exc

    try:
        response_data = json.loads(raw)
    except json.JSONDecodeError as exc:
        raise AssistantError("Appel Groq impossible. La reponse Groq n'est pas un JSON valide.") from exc

    choices = response_data.get("choices") or []
    if not choices:
        raise AssistantError("Appel Groq impossible. La reponse Groq ne contient aucun choix exploitable.")

    message = choices[0].get("message") or {}
    content = safe_text(message.get("content"))
    parsed = extract_json_object(content)
    if not parsed:
        raise AssistantError("Appel Groq impossible. La reponse Groq ne contient pas le JSON attendu.")

    parsed["success"] = True
    parsed["message"] = safe_text(parsed.get("message")) or "Reponse generee par Groq avec succes."
    return parsed


def run_action(action, payload):
    return call_groq(action, payload)


def main():
    try:
        request = json.load(sys.stdin)
        action = safe_text(request.get("action"))
        payload = request.get("payload", {})
        response = run_action(action, payload)
    except AssistantError as exc:
        response = {"success": False, "message": safe_text(exc) or "Assistant IA indisponible."}
    except Exception as exc:  # noqa: BLE001
        response = {"success": False, "message": safe_text(exc) or "Assistant IA indisponible."}

    sys.stdout.write(json.dumps(response, ensure_ascii=False))
    sys.stdout.flush()


if __name__ == "__main__":
    main()
