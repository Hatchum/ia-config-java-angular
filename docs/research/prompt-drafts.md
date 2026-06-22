# Brouillons de prompts & templates de skills (archive)

> Matériau de travail extrait de l'ancien `docs/TASK.md` lors de son éclatement.
> Le contenu **de référence** de TASK.md vit désormais dans
> [`docs/reference/`](../reference/) ; le plan d'implémentation dans
> [`docs/guide/roadmap.md`](../guide/roadmap.md). Ne restent ici que les
> **brouillons réutilisables** (méta-prompts, templates) — à intégrer au besoin
> dans le skill `prompt-creator` / `skill-creator`.

---

## Template de SKILL.md (brouillon détaillé)

```markdown
---
name: [slug-court]
description: Utilise cette skill pour [tâche précise] quand l'utilisateur fournit [entrée] et demande [résultat].
---

# [slug-court]

## Objectif
[Décrire le résultat attendu en une phrase.]

## Quand utiliser cette skill
- [cas 1] / [cas 2] / [cas 3]

## Quand ne pas utiliser cette skill
- [hors périmètre] / [données absentes] / [outil nécessaire non disponible]

## Entrées nécessaires
- [entrée 1] / [entrée 2]

## Niveau de liberté
[high / medium / low freedom] + justification.

## Workflow
1. [Action 1] … 5. [Action 5]   (une seule action par étape)

## Contraintes
- [Contrainte 1] / [Contrainte 2]

## Validation humaine
Demander validation si : [cas sensibles]. Sinon : préparer un brouillon, lister
risques et points à valider, ne pas exécuter l'action finale.

## Ressources internes (si disponibles)
references/ (règles) · templates/ (formats) · examples/ (few-shots) ·
scripts/ (calculs déterministes) · assets/ (non textuel) · tests/ (fiabilité).

## Format de sortie
[Structure attendue]
```

### Taxonomie des dossiers d'un skill (brouillon)

- `references/` — règles métier, procédures, politiques, normes, définitions.
- `templates/` — formats de sortie (e-mails, rapports, tableaux, scripts…).
- `examples/` — few-shots / cas types (stabiliser la sortie, montrer le format).
- `scripts/` — code déterministe (calculs, vérifs, exports). L'IA n'invente pas
  une formule critique.
- `assets/` — éléments non textuels (logos, chartes, icônes).
- `tests/` — cas de test (normaux, complexes, incomplets, hors périmètre, sensibles).

---

## Méta-prompt : transformer une compétence métier en skill

```markdown
Objectif : transformer une compétence métier en skill IA réutilisable.

Compétence à transformer : [COLLER]
Public cible : [COLLER]
Tâche principale : [COLLER]
Entrées disponibles : [LISTE]
Outils disponibles : [LISTE ou "AUCUN OUTIL"]

Procédure :
1. Identifier l'objectif réel de la skill.
2. Définir le nom court de la skill.
3. Rédiger une description de déclenchement.
4. Définir quand utiliser / ne pas utiliser la skill.
5. Lister les entrées nécessaires.
6. Construire une SOP en étapes courtes.
7. Ajouter les contraintes.
8. Ajouter les cas de validation humaine.
9. Définir le format de sortie.
10. Ajouter trois exemples d'usage + une checklist de test.

Contraintes :
- Ne pas commencer par "Tu es". Pas de rôle vague.
- Phrases courtes. Une étape = une action.
- Ne pas inventer de ressource ni supposer qu'un outil existe.
- Signaler les limites. Prévoir les données manquantes.

Format de sortie : un fichier SKILL.md complet en Markdown.
```

---

## Méta-prompt : auditer une skill

```markdown
Objectif : auditer une skill IA et identifier les risques de mauvaise exécution.

Skill à auditer : [COLLER]

Procédure :
1. Objectif clair ? 2. Description → bon déclenchement ?
3. Cas de non-utilisation présents ? 4. Entrées listées ?
5. Procédure assez précise ? 6. Contraintes explicites ?
7. Validation humaine présente ? 8. Format de sortie exploitable ?
9. Risques d'invention / d'action non autorisée ? 10. Version corrigée.

Contraintes : ne pas tout réécrire ; corriger seulement ce qui améliore la
fiabilité ; signaler les points critiques en priorité.

Format : tableau (Élément audité | Problème | Niveau de risque | Correction),
puis "## Version corrigée".
```

---

## Méta-prompt : suite de tests d'une skill

```markdown
Objectif : créer une suite de tests pour vérifier la fiabilité d'une skill IA.

Skill à tester : [COLLER]

Couvrir 5 cas : normal, complexe, données manquantes, hors périmètre,
validation humaine. Pour chacun : entrée, résultat attendu (observable),
erreurs à surveiller. Inclure au moins un cas où la skill doit refuser ou
demander validation. Terminer par une grille d'évaluation
(Critère | Réussi | Échec | Commentaire).
```

---

## Méta-prompt : améliorer une skill à partir d'une erreur

```markdown
Skill actuelle : [COLLER] · Erreur observée : [DÉCRIRE]
Sortie incorrecte : [COLLER] · Sortie attendue : [DÉCRIRE]

Procédure : identifier la cause racine et la classer (objectif flou /
déclenchement / entrée manquante / procédure imprécise / contrainte absente /
exemple absent / format / validation humaine), proposer une correction
minimale, modifier la skill, ajouter un test anti-régression.

Format : ## Diagnostic / ## Cause / ## Correction minimale /
## SKILL.md corrigé / ## Nouveau test ajouté.
```

---

## Méta-prompt : créer une memory à partir d'une skill

```markdown
Objectif : créer une mémoire minimale à partir d'une skill IA.

Extraire : objectif, règles essentielles, procédure, contraintes, cas de
validation humaine, format de sortie. Supprimer exemples longs et répétitions.
Ne pas copier toute la skill ni ajouter d'info absente. Phrases courtes.

Format : # memory.md → ## Sujet / ## Objectif / ## Règles essentielles /
## Procédure / ## Contraintes / ## Validation humaine / ## Format de sortie /
## Erreurs à éviter.
```

---

## Skill complète (brouillon) : `audit-prompt-objectif`

```markdown
---
name: audit-prompt-objectif
description: Utilise cette skill pour auditer un prompt, supprimer les rôles vagues, clarifier l'objectif, ajouter les contraintes, définir le format et améliorer la fiabilité.
---

# Audit de prompt par objectif

## Objectif
Transformer un prompt vague en prompt structuré, fiable et exploitable.

## Quand utiliser
Améliorer / corriger / préciser un prompt ; transformer une demande vague en
instruction ; supprimer un rôle inutile ; créer un prompt professionnel.

## Quand ne pas utiliser
Reformulation purement stylistique ; demande illégale ; données nécessaires
absentes sans hypothèse autorisée ; action exigée sans outil disponible.

## Procédure
1. Lire le prompt. 2. Identifier l'objectif réel. 3-4. Repérer/supprimer les
rôles vagues. 5-6. Remplacer les termes imprécis par des variables.
7-8. Identifier données manquantes et outils nécessaires. 9. Contraintes.
10. Format de sortie. 11. Critères de réussite. 12. Produire le prompt corrigé.

## Contraintes
Ne pas commencer par "Tu es" ; pas de rôle si l'objectif suffit ; ne pas
inventer les données ; ne pas rendre réalisable une tâche impossible ; ne pas
supprimer une contrainte métier ; phrases courtes ; critères observables.

## Validation humaine
Si le prompt engage une décision juridique / financière / de santé, une action
irréversible, ou un usage en production.

## Format de sortie
## Diagnostic (objectif réel, problèmes, données manquantes, risques)
## Prompt corrigé
## Critères de réussite
```

---

## memory.md — synthèse Prompt Engineering (brouillon)

```markdown
## Principe central
Structurer par objectif, pas par rôle vague.

## Structure essentielle
Métadonnées → Objectif → Déclenchement → Entrées → SOP → Contraintes →
Validation humaine → Format → Exemples → Tests.

## Limites
Une skill ne donne pas accès aux données à jour, ne vérifie pas seule les faits,
ne doit pas inventer les données manquantes ni exécuter d'action sensible sans
validation.

## Critère de réussite
Résultat stable, contrôlable, exploitable, conforme aux limites définies.
```
