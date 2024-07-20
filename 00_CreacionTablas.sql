USE master
GO

-------------------------------------------------------------------------
--Creacion de la Base de Datos
-------------------------------------------------------------------------
IF NOT EXISTS (
  SELECT 1 FROM sys.databases WHERE name = 'COM5600G05'
)
BEGIN
  CREATE DATABASE COM5600G05
END
go

USE COM5600G05
GO

-------------------------------------------------------------------------
--Creacion de esquemas
-------------------------------------------------------------------------
IF NOT EXISTS (
  SELECT 1 FROM sys.schemas WHERE name = 'esquemaMedico'
)
  EXEC('CREATE SCHEMA esquemaMedico')
go

IF NOT EXISTS (
  SELECT 1 FROM sys.schemas WHERE name = 'esquemaReserva'
)
  EXEC('CREATE SCHEMA esquemaReserva')
go

IF NOT EXISTS (
  SELECT 1 FROM sys.schemas WHERE name = 'esquemaPaciente'
)
  EXEC('CREATE SCHEMA esquemaPaciente')
go

IF NOT EXISTS (
  SELECT 1 FROM sys.schemas WHERE name = 'esquemaSede'
)
  EXEC('CREATE SCHEMA esquemaSede')
go

-------------------------------------------------------------------------
-- Creacion de tablas
-------------------------------------------------------------------------

/* # Creación de tablas esquemaMedico # */

-- Tabla especialidad
IF NOT EXISTS (
  SELECT 1 
  FROM sys.tables t
  JOIN sys.schemas s ON t.schema_id = s.schema_id
  WHERE t.name = 'especialidad' AND s.name = 'esquemaMedico'
)
BEGIN
  create table esquemaMedico.especialidad 
  (
    idEspecialidad int identity(1,1),
    nombreEspecialidad varchar(50) not null,
  
    constraint PK_especialidad primary key(idEspecialidad),
    constraint UNQ_especialidad unique (nombreEspecialidad)
  )
END

-- Tabla medico
IF NOT EXISTS (
  SELECT 1 
  FROM sys.tables t
  JOIN sys.schemas s ON t.schema_id = s.schema_id
  WHERE t.name = 'medico' AND s.name = 'esquemaMedico'
)
BEGIN
  create table esquemaMedico.medico
  (
    idMedico int identity(1,1),
    nombre varchar(50) not null,
    apellido varchar(50) not null,
    nroMatricula int check(nroMatricula > 0),
    idEspecialidad int,
    activo bit not null default 1, --1 esta activo; 0 no esta activo

    constraint PK_medico primary key(idMedico),
    constraint FK_medico_idEspecialidad foreign key (idEspecialidad) references esquemaMedico.especialidad(idEspecialidad),
    constraint UNQ_medico unique (nroMatricula, idEspecialidad)
  )
END

/* # Creacion tablas esquemaSede # */

-- Tabla sede
IF NOT EXISTS (
  SELECT 1 
  FROM sys.tables t
  JOIN sys.schemas s ON t.schema_id = s.schema_id
  WHERE t.name = 'sede' AND s.name = 'esquemaSede'
)
BEGIN
  create table esquemaSede.sede
  (
    idSede int identity(1,1),
    nombreSede varchar(50) not null,
    direccionSede varchar(50) not null,
    activo bit not null default 1, --1 esta activo; 0 no esta activo
    CONSTRAINT UNQ_sede UNIQUE (nombreSede, direccionSede),
    constraint PK_sede primary key(idSede)
  )
END

/* # Creacion tablas esquemaPaciente # */

-- Tabla usuario
IF NOT EXISTS (
  SELECT 1 
  FROM sys.tables t
  JOIN sys.schemas s ON t.schema_id = s.schema_id
  WHERE t.name = 'usuario' AND s.name = 'esquemaPaciente'
)
BEGIN
  create table esquemaPaciente.usuario 
  (
    idUsuario int identity(1,1),
    contraseña varchar(50),
    fechaDeCreacion datetime default getdate(),

    constraint PK_usuario primary key(idUsuario)
  )
END

-- Tabla domicilio
IF NOT EXISTS (
  SELECT 1 
  FROM sys.tables t
  JOIN sys.schemas s ON t.schema_id = s.schema_id
  WHERE t.name = 'domicilio' AND s.name = 'esquemaPaciente'
)
BEGIN
  create table esquemaPaciente.domicilio 
  (
    idDomicilio int identity(1,1),
    calle varchar(200) not null,
    departamento int check (departamento > 0),
    codigoPostal varchar(50),
    pais varchar(50),
    provincia varchar(50),
    localidad varchar(50),

    constraint PK_domicilio primary key(idDomicilio),
    constraint UNQ_domicilio unique (calle, departamento, codigoPostal, pais, provincia, localidad)
  )
END

-- Tabla prestador
IF NOT EXISTS (
  SELECT 1 
  FROM sys.tables t
  JOIN sys.schemas s ON t.schema_id = s.schema_id
  WHERE t.name = 'prestador' AND s.name = 'esquemaPaciente'
)
BEGIN
  create table esquemaPaciente.prestador 
  (
    idPrestador int identity(1,1),
    nombrePrestador varchar(50) not null,
    planPrestador varchar(50) not null,
    activo bit not null default 1, --1 esta activo; 0 no esta activo

    constraint PK_prestador primary key(idPrestador),
    constraint UNQ_prestador unique (nombreprestador, planprestador)
  )
END

-- Tabla cobertura
IF NOT EXISTS (
  SELECT 1 
  FROM sys.tables t
  JOIN sys.schemas s ON t.schema_id = s.schema_id
  WHERE t.name = 'cobertura' AND s.name = 'esquemaPaciente'
)
BEGIN
  create table esquemaPaciente.cobertura
  (
    idCobertura int identity(1,1),
    imagenCredencial varchar(50),
    nroSocio int check (nroSocio > 0),
    fechaIngreso datetime,
    idPrestador int,
    activo bit not null default 1, --1 esta activo; 0 no esta activo

    constraint PK_cobertura primary key(idCobertura),
    constraint FK_prestador foreign key(idPrestador) references esquemaPaciente.prestador(idPrestador)
  )
END

-- Tabla paciente
IF NOT EXISTS (
  SELECT 1 
  FROM sys.tables t
  JOIN sys.schemas s ON t.schema_id = s.schema_id
  WHERE t.name = 'paciente' AND s.name = 'esquemaPaciente'
)
BEGIN 
  create table esquemaPaciente.paciente
  (
    idHistoriaClinica int identity(1,1),
    nombre varchar(50),
    apellido varchar(50),
    apellidoMaterno varchar(50),
    fechaDeNacimiento varchar(20),
    tipoDocumento varchar(20) check(tipoDocumento like '%[a-Z]%'),
    numeroDeDocumento int check(numeroDeDocumento > 0),
    sexoBiologico varchar(50) check(sexoBiologico in ('Masculino','Femenino')),
    genero varchar(50) check(genero in ('Mujer','Hombre','Trans')),
    nacionalidad char(50),
    fotoDePerfil char(200),
    mail varchar(100) check (mail LIKE '%_@_%._%'),
    telefonoFijo varchar(50),
    telefonoDeContactoAlternativo varchar(50),
    telefonoLaboral varchar(50),
    fechaDeRegistro datetime default getDate(),
    fechaDeActualizacion datetime,
    usuarioActualizacion int,
    idUsuario int,
    idCobertura int,
    idDomicilio int,
    activo bit not null default 1, --1 esta activo; 0 no esta activo

    constraint PK_paciente primary key(idHistoriaClinica),
    constraint FK_paciente_usuario foreign key(idUsuario) references esquemaPaciente.usuario(idUsuario),
    constraint FK_paciente_cobertura foreign key(idCobertura) references esquemaPaciente.cobertura(idCobertura),
    constraint FK_paciente_domicilio foreign key(idDomicilio) references esquemaPaciente.domicilio(idDomicilio),
    constraint UNQ_paciente unique (nombre, apellido, tipoDocumento, numeroDeDocumento)
  )
END

-- Tabla estudio
IF NOT EXISTS (
  SELECT 1 
  FROM sys.tables t
  JOIN sys.schemas s ON t.schema_id = s.schema_id
  WHERE t.name = 'estudio' AND s.name = 'esquemaPaciente'
)
BEGIN
  create table esquemaPaciente.estudio
  (
    idEstudio int identity(1,1),
    fecha datetime,
    nombreEstudio varchar(50) not null,
    autorizado bit not null,
    documentoResultado char(200) not null,
    imagenResultado char(200),
    idHistorialClinico int,

    constraint PK_estudio primary key(idEstudio),
    constraint FK_estudio_historialClinico foreign key(idHistorialClinico) references esquemaPaciente.paciente(idHistoriaClinica)
  )
END

/* # Esquema Reserva*/

-- Tabla tipoTurno
IF NOT EXISTS (
  SELECT 1 
  FROM sys.tables t
  JOIN sys.schemas s ON t.schema_id = s.schema_id
  WHERE t.name = 'tipoTurno' AND s.name = 'esquemaReserva'
)
BEGIN
  create table esquemaReserva.tipoTurno
  (
    idTipoTurno int identity (1,1),
    nombreDelTipoDeTurno varchar(15) not null check(nombreDelTipoDeTurno like '%[a-Z]%'),

    constraint PK_tipoTurno primary key (idTipoTurno),
    constraint UNQ_tipoTurno unique (nombreDelTipoDeTurno)
  )
END

-- Tabla estadoTurno
IF NOT EXISTS (
  SELECT 1 
  FROM sys.tables t
  JOIN sys.schemas s ON t.schema_id = s.schema_id
  WHERE t.name = 'estadoTurno' AND s.name = 'esquemaReserva'
)
BEGIN
  create table esquemaReserva.estadoTurno
  (
    idEstadoTurno int identity (1,1),
    nombreEstado varchar(15) not null check(nombreEstado like '%[a-Z]%'),

    constraint PK_EsatdoTurno primary key (idEstadoTurno),
    constraint UNQ_estadoTurno unique (nombreEstado)
   )
END

-- Tabla reservaDeTurnoMedico
IF NOT EXISTS (
  SELECT 1 
  FROM sys.tables t
  JOIN sys.schemas s ON t.schema_id = s.schema_id
  WHERE t.name = 'reservaDeTurnoMedico' AND s.name = 'esquemaReserva'
)
BEGIN
  create table esquemaReserva.reservaDeTurnoMedico
  (
    idTurno int identity(1,1),
    fecha date not null,
    hora TIME NOT NULL,
    CONSTRAINT chk_hora CHECK (DATEPART(MINUTE, hora) IN (0, 15, 30, 45)),
    idMedico int,
    idEspecialidad int,
    idDireccionAtencion int,
    idEstadoTurno int default 1,
    idTipoTurno int,
    idHistoriaClinica int,

    constraint PK_reserva primary key (idTurno),
    constraint FK_reserva_medico foreign key (idMedico) references esquemaMedico.medico(idMedico),
    constraint FK_reserva_especialidad foreign key (idEspecialidad) references esquemaMedico.especialidad(idEspecialidad),
    constraint FK_reserva_direccionAtencion foreign key (idDireccionAtencion) references esquemaSede.sede(idSede),
    constraint FK_reserva_estadoTurno foreign key (idEstadoTurno) references esquemaReserva.estadoTurno (idEstadoTurno),
    constraint FK_reserva_idHistoriaClinica foreign key (idHistoriaClinica) references esquemaPaciente.paciente(idHistoriaClinica),
    constraint FK_reserva_tipoTurno foreign key (idTipoTurno) references esquemaReserva.tipoTurno(idTipoTurno)
  )
END

-- Tabla diasPorSede
IF NOT EXISTS (
  SELECT 1 
  FROM sys.tables t
  JOIN sys.schemas s ON t.schema_id = s.schema_id
  WHERE t.name = 'diasPorSede' AND s.name = 'esquemaReserva'
)
BEGIN
  create table esquemaReserva.diasPorSede
  (
    idSede int,
    idMedico int,
    dia date,
    horaInicio time not null,
    horaFin time not null,

    constraint PK_diasPorSede primary key(idSede,idMedico,dia),
    constraint FK_diasPorSede_sede foreign key(idSede) references esquemaSede.sede(idSede),
    constraint FK_diasPorSede_idMedico foreign key(idMedico) references esquemaMedico.medico(idMedico),
    constraint UNQ_diasPorSede unique (idMedico, dia, horaInicio, horaFin)
  )
 END
 go

-- Tabla autorizaciones
 IF NOT EXISTS (
  SELECT 1 
  FROM sys.tables t
  JOIN sys.schemas s ON t.schema_id = s.schema_id
  WHERE t.name = 'autorizaciones' AND s.name = 'esquemaPaciente'
)
BEGIN
  create table esquemaPaciente.autorizaciones
  (
    id varchar(20) primary key, 
    Area varchar(20), 
    Estudio varchar(100), 
    Prestador varchar(100), 
    [Plan] varchar(100), 
    PorcentajeCobertura int, 
    Costo int, 
    RequiereAutorizacion bit,

   constraint UNQ_autorizacion unique (Area, Estudio, Prestador, [Plan], PorcentajeCobertura, Costo, RequiereAutorizacion)
  )
END
go