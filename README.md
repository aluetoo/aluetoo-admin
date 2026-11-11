# Aluetoo Admin

Tableau de bord d'administration statique hébergé sur GitHub Pages et connecté à Supabase.

## Fichiers

- `index.html` : interface admin (utilisateurs, bonus, bannissements, annonces, notifications, événements, paramètres et journal).
- `supabase/migrations/001_core_admin.sql` : profils, contrôles de compte, journal, fonctions SQL et politiques RLS.
- `supabase/migrations/002_admin_content_and_settings.sql` : annonces, notifications, événements et paramètres.

## Installation Supabase

1. Ouvre le SQL Editor du projet.
2. Fais d'abord un export/backup des données.
3. Exécute `001_core_admin.sql`, puis `002_admin_content_and_settings.sql`.
4. Vérifie qu'un compte utilisateur existe dans Supabase Auth.
5. Attribue le rôle admin manuellement depuis le SQL Editor, en remplaçant l'adresse ci-dessous par l'adresse du compte administrateur :

```sql
update public.profiles
set role = 'admin'
where id = (
  select id from auth.users
  where email = 'TON-EMAIL-DE-COMPTE'
);
```

Ne donne jamais le rôle admin via un formulaire public. Vérifie que la requête modifie exactement une ligne.

## GitHub Pages

Dans le dépôt GitHub : Settings → Pages → Deploy from a branch → main → /(root). Attends la fin du déploiement.

## Sécurité importante

- La clé `sb_publishable_...` est une clé publique. Elle peut être présente dans le navigateur si RLS est correctement configuré.
- Ne place jamais une clé `sb_secret_...`, `service_role`, un mot de passe ou une clé Groq dans ce dépôt.
- Le code HTML et JavaScript d'un site GitHub Pages est téléchargeable par les visiteurs. La connexion admin protège les données grâce à Supabase Auth et RLS, mais ne rend pas le code source privé.
- Les fonctions SQL sécurisent les opérations bonus et bannissement. Pour que le bannissement et les quotas aient un effet sur les réponses IA, le backend du site Aluetoo Mobile doit contrôler `user_controls` avant de traiter chaque demande.
- Les tables de contenu sont nouvelles et préfixées `aluetoo_`. La migration n'efface aucune ancienne table.

## Attention

Ces migrations sont conçues pour être additives et répétables, mais teste-les d'abord sur une sauvegarde ou un projet de test. Ne supprime pas tes tables existantes pour installer ce tableau de bord.
