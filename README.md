# Aluetoo Admin

Tableau de bord d'administration statique hébergé sur GitHub Pages et connecté au projet Supabase existant.

## Fonctionnalités actuelles

- Connexion via Supabase Auth, avec vérification du rôle `profiles.role = 'admin'`.
- Liste des profils et état des comptes.
- Ajout de 5 messages bonus et bannissement/débannissement via les RPC SQL existantes.
- Création, activation/désactivation et suppression des annonces.
- Création, activation/désactivation et suppression des événements.
- Consultation du journal administrateur.

## Schéma Supabase utilisé

Le tableau de bord utilise les tables déjà présentes dans le projet :

- `profiles` : `id, email, role, created_at`
- `user_controls` : `user_id, bonus_messages, is_banned, ban_reason`
- `admin_audit_log` : `admin_id, target_user_id, action, details, created_at`
- `announcements` : `title, content, is_active, priority, expires_at`
- `events` : `title, description, start_date, end_date, is_active, type`

Les RPC utilisées sont `aluetoo_admin_add_bonus(p_user_id, p_amount, p_reason)` et `aluetoo_admin_set_ban(p_user_id, p_banned, p_reason)`.

## Base de données

La base existante a été inspectée avant adaptation. Les brouillons de migrations initialement présents dans ce dépôt ont été retirés car ils créaient des tables de contenu différentes de celles du projet réel.

Le seul fichier de migration conservé dans ce dépôt est :

- `supabase/migrations/001_admin_manage_existing_content.sql`

Il ajoute des politiques RLS réservant les opérations d'écriture sur `announcements` et `events` aux administrateurs. Cette politique a déjà été appliquée au projet connecté. Ne la réexécute pas manuellement sans vérifier l'historique des migrations.

**Aucune table, aucun compte et aucune donnée existante n'ont été supprimés.**

## Déploiement GitHub Pages

Dans le dépôt GitHub : **Settings → Pages → Deploy from a branch → main → /(root)**. Attends la fin du déploiement.

## Sécurité

- La clé Supabase publishable est publique par conception. La sécurité des données dépend de Supabase Auth, des permissions SQL et des politiques RLS.
- Ne place jamais une clé `sb_secret_...`, `service_role`, un mot de passe ou une clé Groq dans ce dépôt.
- Le code d'un site GitHub Pages est public et téléchargeable. La connexion admin protège les données, pas le code source.
- Les RPC bonus et bannissement vérifient le rôle administrateur dans la base.
- Le backend Aluetoo Mobile utilise maintenant une Edge Function Supabase et une table de quotas privée pour vérifier les bannissements et les limites côté serveur avant chaque appel au modèle IA. La clé Groq doit être configurée comme secret Edge Function `GROQ_API_KEY` et l'ancienne clé exposée doit être révoquée.
