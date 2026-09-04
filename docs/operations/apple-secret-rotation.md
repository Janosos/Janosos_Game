# Rotación del secreto Apple

Rota el client secret de Sign in with Apple al menos cada seis meses y antes de
su expiración. Se necesitan Apple Developer, acceso al Service ID/Key y permisos
de configuración de Auth en Supabase.

1. Crea una nueva key o client secret con la misma Team ID, Key ID y Service ID
   aprobados. No reutilices secretos expirados.
2. Guarda el secreto nuevo en el gestor de secretos; nunca en Git, Flutter
   defines, tickets o logs.
3. Actualiza primero staging y prueba login, vinculación, callback, logout y
   borrado de cuenta.
4. Actualiza producción en una ventana con observación de errores Auth.
5. Conserva el secreto anterior sólo durante la superposición mínima necesaria.
6. Revócalo, confirma que no hay tráfico dependiente y registra fecha/operador
   sin copiar el valor.
7. Agenda la siguiente rotación al menos 30 días antes de expirar.

Si falla, restaura temporalmente el secreto anterior aún válido, pausa nuevas
vinculaciones Apple e investiga IDs/callbacks. Email/password y otras identidades
vinculadas no deben borrarse ni modificarse durante el rollback.
