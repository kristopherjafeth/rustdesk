# Instalador Jimka Soporte (opción sin GitHub Actions)

`JimkaSoporte-Setup.exe`: instalador con la marca Jimka Offshore. No necesita permisos de administrador.

Qué hace:
1. Descarga la última versión oficial de RustDesk para Windows (x64) desde GitHub.
2. La guarda con el nombre `rustdesk-host=rust.jimkaoffshore.com,key=…,.exe`. RustDesk lee el servidor y la clave de ese nombre, así que se conecta solo a nuestro servidor.
3. Crea los accesos "Jimka Soporte" con el ícono de Jimka en el Escritorio y el menú Inicio, más un desinstalador.

Limitaciones frente al cliente compilado: la ventana del programa sigue diciendo "RustDesk" y usa el logo de RustDesk. La marca Jimka aparece en el instalador, los accesos directos y el ícono.

Acceso desatendido: dentro del programa, pulsar "Instalar" (pide administrador) para que quede como servicio, y poner una contraseña permanente.

## Configurar un RustDesk que ya está instalado
Ajustes → Red → ID/Servidor de relay → Importar, y pegar:

```
Qfi0DMYN0b20UdtZ0VXBjRhlHSkZDTaJ1KpBjTTB1bL5GOUJkc0tyaGVDezJndiojI5V2aiwiIiojIpBXYiwiIiojI5FGblJnIsISbvNmLlJ3boNnZm9WYr1Waq5CdzVnciojI0N3boJye
```

O a mano: Servidor ID `rust.jimkaoffshore.com`, Clave `vrsx5Fk+trBT8nKoPSN0i+RZL6dHyaF0WWFmuM6oCX0=`.

## Recompilar el instalador
En Linux: `apt install nsis && makensis JimkaSoporte.nsi`
