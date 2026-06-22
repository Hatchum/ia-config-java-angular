# RAG pour Claude Code

> Synthèse de recherche (juin 2026) sur la mise en place d'un RAG (Retrieval
> Augmented Generation) avec Claude Code. Sources croisées et vérifiées en bas de
> page. **À retenir avant tout :** Claude Code n'utilise **pas** de RAG en natif —
> il fait de la *recherche agentique*. Un RAG est un **ajout optionnel**, utile
> seulement dans des cas précis (gros monorepos, recherche conceptuelle, grosse
> base documentaire).

---

## 1. TL;DR

| Question | Réponse courte |
|----------|----------------|
| Claude Code indexe-t-il mon code (vector DB) ? | **Non.** Il explore à la demande avec `Glob` / `Grep` (ripgrep) / `Read`. |
| Pourquoi pas de RAG natif ? | L'équipe Anthropic a testé RAG + vector DB local très tôt et a constaté que la **recherche agentique faisait mieux** (précision, fraîcheur, confidentialité, simplicité). |
| Existe-t-il quand même un « RAG » officiel ? | Oui, mais côté **Claude.ai Projects** (web/desktop), pas la CLI. Il s'active **automatiquement**, sans config. |
| Comment ajouter un RAG à Claude Code (CLI) ? | Via un **serveur MCP** maison qui expose un outil de recherche sémantique adossé à une vector DB (ChromaDB, LanceDB…). |
| Dois-je le faire sur ce projet ? | **Probablement pas.** Voir §6. Le grep agentique suffit jusqu'à des bases volumineuses. |

---

## 2. Deux sens du mot « RAG pour Claude Code »

Le terme recouvre deux choses très différentes — il faut les distinguer avant de
décider quoi que ce soit.

1. **RAG natif de l'outil Claude Code (CLI)** → *n'existe pas*. Claude Code fait
   de la **recherche agentique** (agentic search) : il lit l'arborescence, devine
   où regarder, lance des `grep`/`glob`, ouvre les fichiers pertinents — comme un
   humain. Aucune indexation, aucun embedding.

2. **RAG comme capacité ajoutée** → ce qu'on « met en place ». Deux pistes :
   - **Claude.ai Projects** (produit web/desktop, pas la CLI) : un RAG officiel
     géré par Anthropic, automatique.
   - **Claude Code (CLI) + serveur MCP** : on branche soi-même un moteur de
     recherche sémantique (vector DB + embeddings) exposé comme outil MCP.

---

## 3. Pourquoi Claude Code n'utilise pas de RAG (recherche agentique)

### Comment ça marche

Claude Code s'appuie sur trois outils, du moins cher au plus cher en tokens :

| Outil | Rôle | Coût |
|-------|------|------|
| `Glob` | Match de chemins par motif (`src/**/*.java`) | quasi nul |
| `Grep` | Recherche regex dans le contenu (moteur **ripgrep**) | léger |
| `Read` | Chargement complet d'un fichier en contexte | 500–5 000 tokens / fichier |

Pour l'exploration lourde, Claude Code délègue à un **sous-agent `Explore`**
(souvent sur un modèle rapide type Haiku) avec sa **propre fenêtre de contexte
isolée**, pour ne pas polluer la conversation principale.

### Les 4 raisons du choix (Boris Cherny, créateur de Claude Code)

> « Early versions of Claude Code used RAG + a local vector db, but we found
> pretty quickly that agentic search generally works better. »

- **Précision** — `grep` trouve les correspondances exactes (noms de fonctions,
  classes, imports) ; les embeddings ajoutent du bruit (faux positifs flous).
- **Fraîcheur** — la lecture du système de fichiers au runtime reflète toujours
  l'état courant ; un index pré-construit *dérive* dès qu'on édite.
- **Confidentialité** — aucune donnée ne quitte la machine pour calculer des
  embeddings.
- **Simplicité** — pas d'index à construire, maintenir, resynchroniser.

### Le bémol : le coût en tokens

La recherche agentique a un risque de **« worst-case cost blow-up »** : sur un
très gros dépôt, des boucles de `grep` sur des termes courants peuvent brûler
beaucoup de tokens. Attention au palier de prix : une requête dépassant
**200 K tokens d'entrée** est facturée plus cher sur l'ensemble de la requête.
Le *prefix caching* (réutilisation du préfixe de prompt, ~90 % de réutilisation
mesurée sur les boucles agentiques) amortit fortement ce coût.

### Validation externe

Un papier Amazon Science (fév. 2026) conclut que *« la recherche par mots-clés via
outils agentiques atteint plus de 90 % de la performance d'un RAG, sans vector
database »* pour les tâches orientées code.

---

## 4. RAG officiel côté Claude.ai Projects (≠ CLI)

Source : centre d'aide officiel Anthropic.

- **Activation : automatique.** Le RAG se déclenche « quand la connaissance du
  projet approche ou dépasse la limite de la fenêtre de contexte ».
- **Configuration : aucune.** Citation officielle : *« No, RAG activates
  automatically when needed. No setup or configuration is required. »*
- **Mécanisme** : Claude utilise un outil de **recherche dans la connaissance du
  projet** pour ne récupérer que les passages pertinents, au lieu de tout charger.
- **Capacité** : jusqu'à **~10× plus de contenu** stockable dans un projet, à
  qualité de réponse équivalente.
- **Réversible** : si la connaissance repasse sous la limite, Claude revient au
  traitement « tout en contexte ».

> ⚠️ Ceci concerne **Claude.ai / l'app Projects**, pas la CLI Claude Code. On ne
> « configure » rien : on téléverse des documents, le reste est géré.

---

## 5. Mettre en place un RAG dans Claude Code (CLI) via MCP

La voie d'extension propre, c'est un **serveur MCP** (Model Context Protocol) qui
expose un (ou des) outil(s) de recherche sémantique. Claude Code y accède comme à
n'importe quel outil. Cf. `docs/guide/mcp.md` pour la mécanique `.mcp.json` / `claude
mcp add` propre à ce kit.

### Architecture type

```
Claude Code (CLI)
   │  (protocole MCP, stdio)
   ▼
Serveur MCP RAG  ──►  Modèle d'embeddings  ──►  Vector DB (ChromaDB / LanceDB)
   ▲                                                   │
   └──────────── outils: search_codebase / rag_query ◄─┘
```

Étapes communes à toutes les implémentations :
1. **Chunking** du code/des docs (en préservant les frontières de fonctions /
   classes ; ex. ~1000 caractères, overlap ~100).
2. **Embeddings** de chaque chunk (modèle local ou API).
3. **Stockage** des vecteurs dans une vector DB.
4. **Serveur MCP** qui expose `search_*` / `index_*` à Claude Code via stdio.
5. **Indexation initiale** puis ré-indexation au fil des évolutions.

### Exemples concrets (open source, juin 2026)

> ⚠️ Projets **communautaires**, non officiels. À auditer avant tout usage en
> entreprise (dépendances, fuite de code vers une API d'embeddings, licences).

**A. Tout local, zéro token / zéro fuite — `claude-code-rag-vector-db`**
- Vector DB : **ChromaDB** (localhost:8000) · Embeddings : **`Xenova/all-MiniLM-L6-v2`** (local, Transformers.js).
- Outils MCP exposés : `search_codebase`, `index_codebase`, `get_index_stats`, `clear_index`.
- Mise en place :
  ```bash
  git clone https://github.com/typhoon1217/claude-code-rag-vector-db.git
  cd claude-code-rag-vector-db && npm install && npm run build
  chroma run --host localhost --port 8000          # démarrer la vector DB
  npm run index-codebase -- --path $(pwd)          # indexer le projet
  ```
  Puis déclarer le serveur MCP (stdio) dans la config Claude Code :
  ```json
  {
    "mcpServers": {
      "rag-context": {
        "command": "node",
        "args": ["dist/src/server/mcp.js"],
        "cwd": "/chemin/vers/claude-code-rag-vector-db"
      }
    }
  }
  ```
- **Reco de l'auteur** : utile surtout au-delà de **~100 Mo** de code (grep > 1 s).
  En dessous, **ripgrep est plus rapide** — ne pas en mettre.

**B. Base documentaire / knowledge base — `mcp-rag-server`**
- Vector DB : **ChromaDB** (Docker) · Embeddings : **OpenAI `text-embedding-3-large`** (⚠️ envoi des données à l'API OpenAI).
- Outils MCP : `rag_query` (hybride), `rag_search` (similarité), `index_document`, `get_stats`.
  ```bash
  docker run -p 8000:8000 chromadb/chroma
  git clone https://github.com/0xrdan/mcp-rag-server.git
  cd mcp-rag-server && npm install && npm run build
  ```
  ```json
  {
    "mcpServers": {
      "rag": {
        "command": "node",
        "args": ["/chemin/vers/dist/server.js"],
        "env": {
          "OPENAI_API_KEY": "sk-...",
          "CHROMA_URL": "http://localhost:8000",
          "CHROMA_COLLECTION": "my_knowledge_base"
        }
      }
    }
  }
  ```

**C. Autres approches référencées**
- **CodeRAG** (LanceDB + sous-agent Claude Code dédié qui orchestre la recherche).
- **mcp-local-rag** (LanceDB *file-based*, sans serveur ; embeddings locaux).
- **RAG-CLI** (ChromaDB + orchestration multi-agents, bridge CLI « zéro token »).

> 🔐 **Garde-fous secrets** : ne jamais committer de clé (`OPENAI_API_KEY`…) dans
> `.mcp.json` versionné. Préférer un embedding **local** (option A) pour éviter
> toute exfiltration de code source vers une API tierce.

---

## 6. Quand un RAG aide vraiment (sinon : recherche agentique)

| Situation | Meilleur choix |
|-----------|----------------|
| Lookup exact de symbole (fonction, classe, import) | **Agentic search** (grep) |
| Session d'édition active (code qui bouge) | **Agentic search** (toujours frais) |
| Confidentialité / pas d'exfiltration | **Agentic search** (local) |
| Petit/moyen dépôt (grep < 1 s) | **Agentic search** |
| Très gros monorepo (millions de lignes) | RAG (grep brûle le contexte) |
| Recherche **conceptuelle** (« où gère-t-on l'auth ? » sans connaître les noms) | RAG (recherche sémantique) |
| Base de **doc/connaissance** volumineuse, hétérogène | RAG |
| Codebase inconnue dont on ne sait pas nommer ce qu'on cherche | RAG |

Règle pratique : **par défaut, rester en recherche agentique.** N'ajouter un RAG
que si l'on observe concrètement le grep ramer ou le contexte exploser, ou pour
une grosse base documentaire externe au code.

---

## 7. Recommandation pour ce projet

Stack du dépôt : Java (Maven multi-module) + un module Angular. Taille très
inférieure au seuil où le RAG devient rentable.

- **Court terme : aucun RAG.** La recherche agentique native (`Grep`/`Glob`/`Read`)
  + un `ARCHITECTURE.md` à jour + des `CLAUDE.md`/skills bien ciblés couvrent le
  besoin, sans coût d'infra ni risque de fuite.
- **Si un besoin émerge** (doc métier volumineuse, plusieurs gros dépôts) :
  privilégier un **serveur MCP RAG 100 % local** (option A, embeddings locaux), et
  le documenter dans `docs/guide/mcp.md`. Jamais de clé d'API dans un `.mcp.json`
  versionné.
- **Optimisations « gratuites » à préférer d'abord** : `ARCHITECTURE.md` précis,
  skills/rules path-scoped, sous-agents `Explore` pour isoler la recherche, et
  bons motifs `Grep`.

---

## 8. Sources (vérifiées, juin 2026)

**Officiel Anthropic**
- [Retrieval augmented generation (RAG) for projects — Claude Help Center](https://support.claude.com/en/articles/11473015-retrieval-augmented-generation-rag-for-projects)
- [Retrieval augmented generation — Claude Cookbook](https://platform.claude.com/cookbook/capabilities-retrieval-augmented-generation-guide)

**Pourquoi Claude Code n'utilise pas de RAG (recherche agentique)**
- [Claude Code Doesn't Index Your Codebase. Here's What It Does Instead — Vadim's blog](https://vadim.blog/claude-code-no-indexing/)
- [Why Claude Code is special for not doing RAG/Vector Search… — Medium (Aram)](https://zerofilter.medium.com/why-claude-code-is-special-for-not-doing-rag-vector-search-agent-search-tool-calling-versus-41b9a6c0f4d9)
- [Why Claude Code Abandoned RAG for Agentic Search — zenn.dev](https://zenn.dev/karamage/articles/2514cf04e0d1ac?locale=en)
- [Settling the RAG Debate… — SmartScope](https://smartscope.blog/en/ai-development/practices/rag-debate-agentic-search-code-exploration/)
- [Why Cursor, Claude Code, and Devin Use grep, Not Vectors — MindStudio](https://www.mindstudio.ai/blog/is-rag-dead-what-ai-agents-use-instead)

**Mise en place d'un RAG via MCP (implémentations communautaires)**
- [typhoon1217/claude-code-rag-vector-db (local, ChromaDB + MiniLM)](https://github.com/typhoon1217/claude-code-rag-vector-db)
- [0xrdan/mcp-rag-server (ChromaDB + OpenAI embeddings)](https://github.com/0xrdan/mcp-rag-server)
- [CodeRAG — Teach Claude Code About Your Codebase with RAG and MCP (LanceDB)](https://levelup.gitconnected.com/stop-writing-code-that-already-exists-teach-claude-code-about-your-codebase-with-rag-and-mcp-baeb64824e71)
- [ItMeDiaTech/rag-cli (ChromaDB + multi-agent)](https://github.com/ItMeDiaTech/rag-cli)
- [Local RAG MCP Server (mcp-local-rag, LanceDB) — Awesome MCP Servers](https://mcpservers.org/servers/shinpr/mcp-local-rag)

**Contre-points / nuances**
- [Coding Agents Skipped RAG — RAG Still Wins on Large Docs — MindStudio](https://www.mindstudio.ai/blog/is-rag-dead-what-ai-coding-agents-use-instead)
- [Why I'm Against Claude Code's Grep-Only Retrieval — Milvus Blog](https://milvus.io/blog/why-im-against-claude-codes-grep-only-retrieval-it-just-burns-too-many-tokens.md)
- [Vector RAG? Agentic Search? Why Not Both? — Alberto Roura](https://albertoroura.com/vector-rag-agentic-search-why-not-both/)
