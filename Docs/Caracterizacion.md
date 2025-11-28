# Documento de Caracterización de Pequeños ISP y sus Prácticas
Alexis Jaramillo

Felipe Velasco

## 1. Introducción

La caracterización de pequeños Proveedores de Servicios de Internet (ISP) en Colombia, particularmente en el Valle del Cauca, es fundamental para entender sus necesidades operativas, desafíos tecnológicos y oportunidades de mejora en la gestión de sus redes. Este documento presenta un análisis de las características técnicas, organizacionales y operacionales de estos operadores, con énfasis en sus prácticas de monitoreo y gestión de red[1].

Colombia cuenta con 3.409 proveedores de servicio a Internet registrados, de los cuales una proporción significativa corresponde a pequeños operadores locales y regionales[2]. En el Valle del Cauca específicamente, estos operadores representan una infraestructura clave para la conectividad rural y periurbana, atendiendo poblaciones donde los grandes operadores tienen cobertura limitada[2].

## 2. Contexto Regional: Pequeños ISP en el Valle del Cauca

### 2.1 Presencia y Cobertura

El Valle del Cauca es uno de los departamentos con mayor cantidad de ISP locales en Colombia, junto con Bogotá, Antioquia, Cundinamarca y Santander[2]. Estos pequeños operadores han desarrollado redes que alcanzan municipios y corregimientos donde operadores nacionales como Claro, Movistar y ETB tienen presencia limitada o nula[3].

En municipios como Palmira, Cartago, Zarzal, Roldanillo y otros del Valle del Cauca, los pequeños ISP ofrecen:

- Conectividad mediante fibra óptica de última milla (donde se ha desplegado infraestructura)
- Tecnología inalámbrica (WiMAX, radio enlace punto a punto)
- Enlaces de respaldo mediante conexiones de satélite
- Servicios de acceso a Internet para usuarios residenciales, pequeñas empresas y negocios locales[3][4]

### 2.2 Estrategia de Negocio y Modelo Operativo

Los pequeños ISP en la región operan típicamente con:

- Equipo técnico reducido (1-5 personas para gestión de red y soporte técnico)
- Presupuestos limitados para inversión en infraestructura y herramientas de gestión
- Redes híbridas que combinan distintas tecnologías de acceso según la geografía del servicio
- Operación descentralizada, con centros de acceso distribuidos por varios municipios[2]

Su modelo de negocio se enfoca en ofrecer conectividad de última milla con precios competitivos locales, complementando o compitiendo con operadores nacionales en segmentos residenciales y PYMES[2].

## 3. Características Técnicas de la Infraestructura

### 3.1 Arquitectura de Red Típica

Con base en el análisis de la infraestructura del ISP de referencia en Palmira y en prácticas documentadas en pequeños operadores, la arquitectura típica de un pequeño ISP comprende:
![Arquitectura ISP palmira](/Anexos/Diagrama-red-ISP.png)


**Niveles de Red:**

1. **Nivel de Backbone o Troncal**: Enlace de conectividad con un ISP proveedor nacional o regional, generalmente mediante fibra óptica o enlaces de radiofrecuencia dedicados. Este enlace suele ser el "upstream" de la red y representa el punto crítico de disponibilidad.

2. **Nivel de Distribución**: Concentradores (hubs) o routers de acceso distribuidos en distintos sectores geográficos. Estos dispositivos reciben el tráfico del backbone y lo distribuyen a los usuarios finales. En el caso estudiado, la red de Palmira utiliza routers MikroTik Cloud Core como concentradores centrales, que enlazan múltiples sectores.

3. **Nivel de Acceso**: Puntos finales de red (switches, routers de acceso, puntos de acceso inalámbrico) que conectan directamente a usuarios residenciales y comerciales. Pueden estar en postes, cajas de empalme o instalaciones en el domicilio del cliente.

**Componentes Principales Observados:**

- **Routers Centrales**: MikroTik Cloud Core CCR1036-8G-2S+ o equipamiento similar (procesadores potentes, múltiples interfaces de fibra)
- **Switches de Acceso**: TP-Link, Huawei, Cisco u otros fabricantes comerciales
- **Enlaces Troncales**: Fibra óptica monomodo, enlaces de radio enlace (millimetra) para conectar edificios o sectores
- **Supervisión y Herramientas**: Sistemas básicos de monitoreo (WhatSup SNM, herramientas propietarias simples, o gestión manual)
- **Servidores**: Típicamente servidores básicos (Dell o equivalente) para alojar servicios de autenticación, dhcp, dns y soporte técnico

![Herramienta de monitoreo pequeño ISP](/Anexos/wsup.PNG)

### 3.2 Tecnologías de Acceso Empleadas

Los pequeños ISP del Valle del Cauca utilizan principalmente:

- **Fibra Óptica de Última Milla (FTTX)**: En zonas urbanas y periurbanas con densidad de usuarios suficiente
- **Radio Enlace Inalámbrico**: Conexiones punto a multipunto (PMP) u punto a punto (P2P) para alcanzar sectores dispersos
- **ADSL Hereditario**: Aún en algunos casos donde existe infraestructura heredada de ETB o telecom antiguos
- **4G/LTE**: Como respaldo o complemento en zonas con cobertura móvil[3][4]

La elección de tecnología depende de la geografía, densidad de demanda, inversión disponible y disponibilidad de infraestructura preexistente.

### 3.3 Dispositivos de Red Empleados

Según la información de la arquitectura analizada, los fabricantes más utilizados son:

| Dispositivo | Fabricante | Modelo Típico | Función |
|---|---|---|---|
| Router Central | MikroTik | CCR1036-8G-2S+ | Agregación de tráfico, enrutamiento principal |
| Switch | TP-Link / Huawei | TLS G2216 / S2350 | Distribución de conectividad nivel 2 |
| Router Acceso | TP-Link | Diversos modelos | Distribución de clientes |
| Firewall/Proxy | Huawei / Sophos | Diversos | Seguridad y control de ancho de banda |
| Servidor Aplicaciones | Dell | PowerEdge R710 | Servicios de soporte (DNS, DHCP, autenticación) |

Estos dispositivos se caracterizan por ser de entrada/media gama en el mercado, balanceando funcionalidad, costo y disponibilidad de repuestos locales[2].

## 4. Prácticas Actuales de Monitoreo y Gestión

### 4.1 Herramientas de Monitoreo Utilizadas

Los pequeños ISP típicamente emplean:

**Herramientas Comerciales Ligeras:**
- Monitoreo básico integrado en routers (MikroTik Winbox, interfaces web de switches)
- Software de licencia de bajo costo o versiones gratuitas de plataformas NMS (Network Management Systems)
- Herramientas de diagnóstico puntuales (ping, traceroute, netflow) ejecutadas manualmente

**Herramientas Propietarias o Caseras:**
- Algunos operadores desarrollan scripts simples (bash, python) para alertas básicas vía SMS o correo
- Consulta manual de logs de dispositivos
- Control de tickets informal o en hojas de cálculo

**Limitaciones Documentadas:**
- Falta de visión unificada del estado de la red en tiempo real
- Detección reactiva (cliente reporta problema) en lugar de proactiva
- Dificultad para correlacionar eventos en distintos niveles de la red
- Ausencia de históricos consolidados para análisis de tendencias[5]

La imagen proporcionada (WhatSup SNM) ilustra un ejemplo de herramienta básica de monitoreo SNMP, que algunos pequeños ISP utilizan en entornos de laboratorio o desarrollo pero que raramente está en producción 24/7 por limitaciones de licencia o conocimiento técnico para administrarlo.

### 4.2 Métricas y Alertas Comúnmente Monitoreadas

Cuando existe monitoreo formal, los pequeños ISP se enfocan en:

- **Disponibilidad**: Si el router/switch está reachable (ICMP ping)
- **Uso de CPU y Memoria**: En routers centrales y switches
- **Uso de Interfaces**: Ancho de banda consumido, número de conexiones activas
- **Alertas de Caída**: Notificación cuando un dispositivo se desconecta
- **Uptime de Servicios**: Disponibilidad de acceso a Internet para clientes

Métricas típicamente **NO monitoreadas** en pequeños ISP:

- Latencia y jitter en rutas específicas
- Pérdida de paquetes
- QoS y cumplimiento de SLA
- Análisis de tráfico por tipo de aplicación
- Predicción de agotamiento de recursos
- Seguridad: detección de anomalías, ataques DDoS

### 4.3 Prácticas de Respuesta a Incidentes

Los pequeños ISP operan típicamente con:

- **Disponibilidad de Soporte**: Horario comercial (8am-6pm) en algunos casos; soporte limitado fuera de horario
- **Escalación**: Llamadas telefónicas directas a técnicos, coordinación informal
- **Documentación**: Mínima; conocimiento en cabeza de técnicos senior
- **Cambios de Configuración**: Realizados sin control de versiones formal; riesgo de pérdida de configuración o cambios no documentados
- **Mantenimiento Preventivo**: Reducido a actualizaciones puntuales; sin plan de mantenimiento programado

## 5. Restricciones y Desafíos Identificados

### 5.1 Restricciones Técnicas

1. **Limitaciones de Herramientas Disponibles**: Las plataformas NMS comerciales (Zabbix enterprise, Cisco Prime, Fortinet) tienen costos prohibitivos. Las versiones open source requieren experticia técnica que muchos pequeños ISP no poseen.

2. **Infraestructura de Soporte Insuficiente**: Falta de servidor dedicado para monitoreo, backup limitado, sincronización de tiempo inadecuada para correlacionar eventos.

3. **Conectividad Hacia Upstream**: Dependencia de un único enlace troncal; falta de redundancia, lo que complica la detección remota cuando el enlace principal falla.

4. **Compatibilidad SNMP**: No todos los dispositivos antiguos de red soportan SNMP v2c/v3; algunos requieren configuración manual complicada.

### 5.2 Restricciones Organizacionales

1. **Personal Técnico Limitado**: 1-2 técnicos de red por pequeño ISP; imposibilidad de turno 24/7 real. Alto riesgo si la persona clave se ausenta.

2. **Presupuesto Reducido**: Inversión anual en software/herramientas < $5.000 USD en muchos casos. Prioridad en expansión de cobertura sobre gestión operativa.

3. **Falta de Capacitación**: Técnicos auto-capacitados o con formación técnica básica, sin especialización en gestión de redes a nivel enterprise.

4. **Procesos Informales**: Ausencia de políticas documentadas, cambios no autorizados, falta de control de acceso a configuraciones críticas.

### 5.3 Restricciones Económicas

1. **Márgenes Reducidos**: Competencia fuerte con operadores nacionales; presiones para mantener precios bajos limita inversión en IT.

2. **Capex vs. Opex**: Preferencia por gastos en infraestructura física (fibra, routers) sobre herramientas de software.

3. **Impacto de Downtime**: Caída de red resulta en pérdida inmediata de ingresos, pero inversión preventiva se ve como "gasto sin retorno evidente".

## 6. Resultados de Pruebas de Laboratorio

Se realizaron pruebas de monitoreo en el laboratorio de la universidad utilizando el prototipo de plataforma LibreNMS. Los resultados validaron lo siguiente:

### 6.1 Configuración de Prueba

- **Dispositivos Monitoreados**: Router MikroTik Cloud Core CCR1036-8G-2S+ (similar a los empleados en pequeños ISP)
- **Plataforma de Monitoreo**: LibreNMS desplegada en Raspberry Pi (prototipo de bajo costo)
- **Protocolo**: SNMP v2c
- **Intervalo de Polling**: 5 minutos

### 6.2 Capacidades Validadas

✓ **Descubrimiento automático de dispositivos** mediante SNMP walk  
✓ **Recolección de métricas** de CPU, memoria, interfaces, tráfico  
✓ **Gráficos históricos** de uso de ancho de banda  
✓ **Alertas configurables** para umbrales de recursos  
✓ **Mapeo topológico** básico de la red de prueba  
✓ **Interfaz web intuitive** accesible desde laptop o tableta  

### 6.3 Implicaciones para Pequeños ISP

Estos resultados indican que una plataforma como LibreNMS, instalada en hardware de bajo costo (Raspberry Pi o servidor usado), es viable técnica y económicamente para pequeños ISP, resolviendo su falta de herramientas de monitoreo sin requerir inversión significativa ni expertise avanzada.

## 7. Conclusiones de la Caracterización

1. **Heterogeneidad**: No existe un pequeño ISP "típico"; varían significativamente en tamaño, tecnología y madurez operativa.

2. **Brecha de Herramientas**: Existe un vacío entre las necesidades de monitoreo/gestión y las soluciones disponibles (muy caras o muy complejas).

3. **Importancia Operativa Creciente**: A medida que los ISP expanden servicios (video, VoIP, IoT), la gestión de red proactiva se vuelve crítica.

4. **Oportunidad de Mejora**: Soluciones open source como LibreNMS, adaptadas a realidades de pequeños operadores, pueden generar valor significativo en efectividad operativa y calidad percibida del servicio.

5. **Sostenibilidad Regional**: El fortalecimiento de pequeños ISP mediante mejores herramientas de gestión contribuye a la sostenibilidad de la conectividad en zonas donde operadores nacionales no tienen alcance rentable.

---

## Referencias

[1] Comisión de Regulación de Comunicaciones (CRC). (2023). *Características de la red infraestructura desplegada por los ISP*. Esquemas Técnicos de Conectividad. Gobierno de Colombia.

[2] Impacto TIC. (2025). *Internet en zonas rurales en Colombia: Precios, empresas y cobertura*. Recuperado 28 de noviembre de 2025, de https://impactotic.co/innovacion/transformacion-digital/internet-en-zonas-rurales-en-colombia/

[3] Claro Colombia. (2023). *Claro lleva su fibra óptica a Cartago, Zarzal, Roldanillo*. Recuperado 28 de noviembre de 2025, de https://www.claro.com.co/institucional/fibra-optica-cartago/

[4] Corfi. (2024). *Informe infraestructura digital* (Versión final, 31 de octubre de 2024). Investigaciones Corfi.

[5] Paessler. (2024). *Monitoreo de ISP (ISP Monitoring)*. PRTG Network Monitor. Recuperado 28 de noviembre de 2025, de https://www.paessler.com/es/monitoring/network/isp-monitoring-tool

[6] Proyectos Tipo DNP. (s.f.). *Zonas Digitales de Acceso Público Gratuito*. Recuperado 28 de noviembre de 2025, de https://proyectostipo.dnp.gov.co/

[7] ProLyam. (2025). *Software de gestión para ISP: beneficios y cómo elegirlo*. Recuperado 28 de noviembre de 2025, de https://prolyam.com/software-de-gestion-para-isp/

[8] Kinsta. (2025). *¿Qué Es un ISP? Todo Lo Que Necesitas Saber*. Recuperado 28 de noviembre de 2025, de https://kinsta.com/es/blog/que-es-un-isp/

---

**Fecha: Noviembre de 2025**
**Institución: Universidad ICESI, Programa