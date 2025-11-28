---
title: "Especificación de Requisitos para la Plataforma de Gestión de Red en Pequeños ISP"
author: "Alexis Jaramillo Martínez – Felipe Velasco Sánchez"
date: "Noviembre de 2025"
---

# 1. Introducción

Este documento define los requisitos funcionales, no funcionales y técnicos de una plataforma de gestión de red basada en software de código abierto, dirigida a pequeños Proveedores de Servicios de Internet (ISP) del Valle del Cauca. 

Los requisitos se derivan de la caracterización de estos operadores, su arquitectura de red típica y las limitaciones identificadas en sus prácticas actuales de monitoreo y operación. 


---

# 2. Alcance y objetivos de la plataforma

La plataforma propuesta se concibe como un sistema centralizado de monitoreo y gestión que permita a los pequeños ISP:

- Vigilar en tiempo casi real el estado de routers, switches y enlaces críticos. 

- Detectar de forma temprana fallos y degradaciones de servicio. 
- Disponer de históricos de desempeño que faciliten la planificación de capacidad y el soporte técnico.

El alcance incluye redes de tamaño pequeño a mediano (hasta varios cientos de dispositivos), con topologías en tres niveles (troncal, distribución y acceso), y se apoya en herramientas como LibreNMS para su implementación. 

---

# 3. Requisitos funcionales

## 3.1 Descubrimiento y registro de dispositivos

**RF-01 – Descubrimiento automático básico**  
La plataforma deberá descubrir y registrar automáticamente dispositivos de red compatibles (routers, switches, radios, servidores) mediante SNMP, ICMP y mecanismos de auto-discovery (XDP, ARP, OSPF, BGP).  

**RF-02 – Edición manual de dispositivos**  
La plataforma deberá permitir agregar, editar y eliminar dispositivos de forma manual, definiendo IP, nombre, tipo, comunidad SNMP y grupo lógico al que pertenecen.  

**RF-03 – Agrupación por zonas y roles**  
La plataforma deberá organizar los dispositivos por categorías (troncal, distribución, acceso, laboratorio) y por zonas geográficas (municipio, barrio, sector), facilitando vistas filtradas. 

## 3.2 Monitoreo de estado y desempeño

**RF-04 – Monitoreo de disponibilidad**  
La plataforma deberá verificar periódicamente la disponibilidad de los dispositivos mediante ICMP y SNMP, registrando eventos de caída y recuperación.   

**RF-05 – Monitoreo de recursos**  
La plataforma deberá recolectar y almacenar métricas de CPU, memoria, uso de disco (cuando aplique) y temperaturas de equipos críticos. 

**RF-06 – Monitoreo de interfaces y enlaces**  
La plataforma deberá monitorear las interfaces de red (ancho de banda utilizado, errores, descartes) en enlaces troncales y de distribución, generando gráficas históricas. 

**RF-07 – Monitoreo de servicios básicos**  
La plataforma deberá verificar la disponibilidad de servicios esenciales (DNS, DHCP, autenticación PPPoE, servidores de facturación, etc.) mediante sondas simples (ping, puerto TCP, HTTP).

## 3.3 Alertamiento y notificaciones

**RF-08 – Gestión de umbrales y reglas de alerta**  
La plataforma deberá permitir definir umbrales de alerta para disponibilidad, utilización de CPU, memoria, interfaces y otros parámetros críticos. 

**RF-09 – Notificación a múltiples canales**  
La plataforma deberá enviar notificaciones de alertas por al menos dos canales configurables (correo electrónico y mensajería instantánea o webhook), con posibilidad de definir horarios de silencio. 

**RF-10 – Priorización de eventos**  
La plataforma deberá clasificar las alertas por niveles de criticidad (crítica, mayor, menor, informativa) para priorizar la atención por parte del reducido equipo técnico.

## 3.4 Visualización y reportes

**RF-11 – Panel de control general**  
La plataforma deberá ofrecer un panel principal con el resumen de estado de la red (dispositivos activos/inactivos, alertas abiertas, enlaces más cargados). 

**RF-12 – Gráficas históricas de desempeño**  
La plataforma deberá generar gráficas históricas de tráfico y recursos, con diferentes escalas de tiempo (últimas horas, días, semanas, meses) para soportar decisiones de ampliación de capacidad. 

**RF-13 – Mapas lógicos o topológicos**  
La plataforma deberá ofrecer una visualización topológica básica de la red (nodos y enlaces), permitiendo identificar rápidamente el impacto de fallos. 

**RF-14 – Reportes programados**  
La plataforma deberá permitir configurar reportes periódicos (por ejemplo, semanales o mensuales) de disponibilidad y uso de enlaces clave, enviados por correo a los administradores. 

## 3.5 Gestión de usuarios y seguridad operativa

**RF-15 – Autenticación y perfiles de usuario**  
La plataforma deberá manejar autenticación de usuarios y al menos dos perfiles: administrador (configuración completa) y operador (solo consulta y reconocimiento de alertas). 

**RF-16 – Registro de actividades**  
La plataforma deberá mantener un registro de acceso y acciones relevantes (login, cambios de configuración, altas/bajas de dispositivos) para auditoría básica. 

---

# 4. Requisitos no funcionales

## 4.1 Rendimiento y escalabilidad

**RNF-01 – Capacidad de monitoreo inicial**  
La plataforma deberá soportar, en su configuración base sobre Raspberry Pi o servidor equivalente, al menos 100 dispositivos y 1.000 interfaces monitoreadas, manteniendo tiempos de respuesta aceptables en la interfaz web. 

**RNF-02 – Escalabilidad progresiva**  
La arquitectura deberá permitir escalar horizontal o verticalmente (por ejemplo, migrando a un servidor más potente o distribuyendo pollers) para llegar a monitorear hasta 500 dispositivos si el ISP crece. 

## 4.2 Disponibilidad y confiabilidad

**RNF-03 – Disponibilidad de la plataforma**  
La plataforma deberá diseñarse para una disponibilidad mínima del 99 %, considerando que presta servicio principalmente en horario laboral y que puede programarse mantenimiento en horas valle. 

**RNF-04 – Tolerancia a fallos moderada**  
Se deberán contemplar respaldos periódicos de la base de datos y configuraciones, de forma que un fallo en el servidor de monitoreo no implique pérdida total de datos históricos.

## 4.3 Usabilidad

**RNF-05 – Interfaz web amigable**  
La plataforma deberá ofrecer una interfaz web responsiva, accesible desde navegadores estándar y comprensible para técnicos con formación técnica media, minimizando la necesidad de entrenamiento extenso. 

**RNF-06 – Idioma**  
La interfaz deberá estar disponible, al menos, en inglés; se considerará deseable soporte en español para facilitar la adopción por personal local. 

## 4.4 Seguridad

**RNF-07 – Acceso autenticado**  
Todas las funciones administrativas deberán requerir autenticación.

**RNF-08 – Comunicaciones seguras**  
Se recomienda soportar acceso cifrado mediante HTTPS, especialmente si la plataforma se expone fuera de la red de administración del ISP.  

**RNF-09 – Manejo de credenciales SNMP**  
Las credenciales SNMP deberán almacenarse de forma protegida y se fomentará el uso de SNMPv3 cuando el equipamiento del ISP lo soporte. 

## 4.5 Mantenibilidad

**RNF-10 – Instalación y actualización simplificadas**  
La plataforma deberá poder instalarse siguiendo una guía de despliegue rápido, con scripts de automatización cuando sea posible, y permitir actualizaciones sin interrupciones prolongadas.  

**RNF-11 – Documentación**  
Se deberá contar con documentación clara de instalación, configuración básica y operación cotidiana, adaptada al contexto de pequeños ISP de la región.  

---

# 5. Requisitos técnicos

## 5.1 Plataforma de software

**RT-01 – Base en software de código abierto**  
La solución se basará en una plataforma NMS open source (por ejemplo, LibreNMS), con licencia que permita su uso y adaptación sin costos de licenciamiento por dispositivo.    

**RT-02 – Sistema operativo**  
Se utilizará un sistema operativo Linux estable (por ejemplo, Ubuntu Server o Debian) con soporte a largo plazo y comunidad activa.  

**RT-03 – Componentes de software**  
La plataforma deberá utilizar componentes estándar: servidor web (Nginx o Apache), PHP, base de datos MariaDB o MySQL, y servicios SNMP y cron para tareas programadas.  

## 5.2 Hardware objetivo

**RT-04 – Despliegue en Raspberry Pi**  
La plataforma deberá poder desplegarse en una Raspberry Pi, ya que el servidor actual Windows 7 no soporta la instalacion de Librenms

**RT-05 – Despliegue en servidor x86**  
Para otros ISP se tendra una guia de despliegue en un servidor x86

## 5.3 Integración con la red del ISP

**RT-06 – Compatibilidad con equipamiento existente**  
La plataforma deberá soportar monitoreo de dispositivos MikroTik, Huawei, TP-Link y otros equipos presentes en la red del ISP mediante SNMP, ICMP y, cuando aplique, protocolos de descubrimiento vecinos.  

---

# 6. Conclusiones

Los requisitos aquí definidos orientan el diseño de una plataforma de gestión de red alineada con la realidad de los pequeños ISP del Valle del Cauca: presupuestos ajustados, equipos técnicos reducidos y redes cada vez más complejas. 

Su implementación con herramientas de código abierto como LibreNMS, sobre hardware accesible como Raspberry Pi y servidores reutilizados, permite cerrar de manera pragmática la brecha de monitoreo y mejorar la calidad del servicio ofrecido a los usuarios finales.


---
