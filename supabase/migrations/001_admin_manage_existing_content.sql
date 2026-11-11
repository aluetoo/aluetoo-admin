-- Aluetoo Admin: permissions for the content tables already present in this project.
-- This migration does not create, rename, or delete tables.
DROP POLICY IF EXISTS "admin_manage_announcements" ON public.announcements;
CREATE POLICY "admin_manage_announcements"
ON public.announcements
FOR ALL
TO authenticated
USING (public.is_aluetoo_admin())
WITH CHECK (public.is_aluetoo_admin());

DROP POLICY IF EXISTS "admin_manage_events" ON public.events;
CREATE POLICY "admin_manage_events"
ON public.events
FOR ALL
TO authenticated
USING (public.is_aluetoo_admin())
WITH CHECK (public.is_aluetoo_admin());
