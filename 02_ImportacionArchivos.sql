use COM5600G05
go

SET NOCOUNT ON;
go
-------------------------------------------------------------------------
--Corrección errores caracteres
-------------------------------------------------------------------------
CREATE or alter FUNCTION esquemaPaciente.corregirCampo(@nombre varchar(200))
RETURNS VARCHAR(200)
AS
BEGIN

    set @nombre = replace(@nombre,'Ã€','á'); -- á
    set @nombre = replace(@nombre,'Ã ','á'); -- á
    set @nombre = replace(@nombre,'Ã','á'); -- á
    set @nombre = replace(@nombre,'Ã¡','á'); -- á
    set @nombre = replace(@nombre,'Ãš','ú'); -- ú
    set @nombre = replace(@nombre,'Ã¹','ú'); -- ú
    set @nombre = replace(@nombre,'Ãº','ú'); -- ú
    SET @nombre = REPLACE(@nombre,'Ã±','ñ'); -- ñ
    set @nombre = replace(@nombre,'Ã‘','ñ'); --ñ
    set @nombre = REPLACE(@nombre,'Ã­','í'); -- í
    set @nombre = REPLACE(@nombre,'Ã¬','í'); -- í
    set @nombre = REPLACE(@nombre,'Ã','í'); -- í
    set @nombre = REPLACE(@nombre,'Ã©','é'); -- é
    set @nombre = REPLACE(@nombre,'Ã¨','é'); -- é
    set @nombre = REPLACE(@nombre,'Ã¨','é'); -- é
    set @nombre = REPLACE(@nombre,'Ã‰','é'); -- é
    set @nombre = REPLACE(@nombre,'Ãª','é'); -- é
    set @nombre = REPLACE(@nombre,'Ã³','ó'); -- ó
    set @nombre = REPLACE(@nombre,'Ã²','ó'); -- ó
    set @nombre = REPLACE(@nombre,'Ã“','ó'); -- ó
  set @nombre = REPLACE(@nombre,'NÂº','Nº'); -- Nº
    RETURN @nombre;
END
go

-------------------------------------------------------------------------
--Importaciones de autorizaciones
-------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE esquemaPaciente.importarAutorizaciones 
(
    @rutaArchivo VARCHAR(2100)
)
AS
BEGIN
  create table #autorizacionesTemporal
  (
    id varchar(20), 
    Area varchar(20), 
    Estudio varchar(100), 
    Prestador varchar(100), 
    [Plan] varchar(100), 
    PorcentajeCobertura int, 
    Costo int, 
    RequiereAutorizacion bit
  )

  declare @sql nvarchar(max)
  set @sql='INSERT INTO #autorizacionesTemporal
    (id,Area, Estudio, Prestador, [Plan], PorcentajeCobertura, Costo, RequiereAutorizacion)
    SELECT 
        id, 
        Area, 
        Estudio, 
        Prestador, 
        [Plan], 
        PorcentajeCobertura, 
        Costo, 
    RequiereAutorizacion
    FROM 
        OPENROWSET (BULK''' +  @rutaArchivo + ''', SINGLE_CLOB) AS j
    CROSS APPLY 
        OPENJSON(BulkColumn)
    WITH 
    (
    id varchar(20) ''$._id."$oid"'', 
        Area VARCHAR(20) ''$.Area'', 
        Estudio VARCHAR(100) ''$.Estudio'', 
        Prestador VARCHAR(100) ''$.Prestador'', 
        [Plan] VARCHAR(100) ''$.Plan'', 
        PorcentajeCobertura INT ''$."Porcentaje Cobertura"'', 
        Costo INT ''$.Costo'', 
        RequiereAutorizacion BIT ''$."Requiere autorizacion"''
    )'
  Exec sp_executesql @sql

  update #autorizacionesTemporal set Estudio= esquemaPaciente.corregirCampo(Estudio),[Plan]= esquemaPaciente.corregirCampo([Plan])

  INSERT INTO esquemaPaciente.autorizaciones
    (id,Area, Estudio, Prestador,[Plan], PorcentajeCobertura, Costo, RequiereAutorizacion)
  SELECT id,Area, Estudio, Prestador,[Plan], PorcentajeCobertura, Costo, RequiereAutorizacion 
    from #autorizacionesTemporal
    where id not in (select id
            from esquemaPaciente.autorizaciones
                    )
END
GO

--- Ejemplo de consulta para que te salga algo que contenga Análisis
--select * from autorizaciones2 WHERE Estudio COLLATE Modern_Spanish_CI_AI LIKE '%Ana%'

-------------------------------------------------------------------------
--Importacion Sedes
-------------------------------------------------------------------------
create or alter procedure esquemaSede.importarArchivoSedes (
  @rutaArchivo varchar(2100)
)
as
begin
  create table #sedeTemporal (
  nombreSede varchar(100) not null,
  direccionSede varchar(200) not null,
  localidad varchar(200) not null,
  provincia varchar(200) not null
  )

  declare @sqlSede nvarchar(1000) 
  set @sqlSede = '
    bulk insert #sedeTemporal
    from ''' + @rutaArchivo + '''
    with
    (
      FIELDTERMINATOR = '';'',
      ROWTERMINATOR = ''0x0A'',
      CODEPAGE = ''ACP'',
      Firstrow = 2
    );
  '
  Exec sp_executesql @sqlSede

  -- Corregir campos
  update #sedeTemporal set nombreSede= esquemaPaciente.corregirCampo(nombreSede),direccionSede= esquemaPaciente.corregirCampo(direccionSede)

  --insert #sedeTemporal into esquemaSede.Sede
  insert into esquemaSede.Sede (nombreSede,direccionSede) 
  select nombreSede,direccionSede 
  from #sedeTemporal
  where nombreSede not in (select s.nombreSede
                from esquemaSede.sede s
                )

  --Borrar tabla temporal
  drop table #sedeTemporal
end
go



-------------------------------------------------------------------------
--Importacion Datos Médicos
-------------------------------------------------------------------------
create or alter procedure esquemaMedico.importarArchivoMedicos(
  @rutaArchivo varchar(2100)
  )
  as
  begin
    create table #MedicosTemporal (
    nombre varchar(100) not null,
    apellido varchar(200) not null,
    especialidad varchar(200) not null,
    numMatricula int not null,
    )
    declare @idEspecialidad int
    declare @sqlmedico nvarchar(1000) 
    set @sqlmedico = '
      bulk insert #MedicosTemporal
      from ''' + @rutaArchivo + '''
      with
      (
        FIELDTERMINATOR = '';'',
        ROWTERMINATOR = ''0x0A'',
        CODEPAGE = ''ACP'',
        Firstrow = 2
      );
    '
    Exec sp_executesql @sqlmedico

  update #MedicosTemporal 
    set nombre=replace(nombre,'Dr.',' '),
    apellido=esquemaPaciente.corregirCampo(apellido),
    especialidad= upper(esquemaPaciente.corregirCampo(especialidad))

  update #MedicosTemporal 
    set nombre=replace(nombre,'Dra. ',' ')


  insert into esquemaMedico.especialidad (nombreEspecialidad)
  select distinct especialidad
  from #MedicosTemporal
  where especialidad collate Modern_Spanish_CI_AI not in (
    select nombreEspecialidad
    from esquemaMedico.especialidad 
    )


  insert into esquemaMedico.medico (nombre,apellido,nroMatricula,idEspecialidad) 
        select nombre,apellido,numMatricula,idEspecialidad 
    from #MedicosTemporal
        inner join esquemaMedico.especialidad on especialidad=nombreEspecialidad
        where numMatricula not in (
                              select numMatricula
                  from esquemaMedico.medico
                  )

  --Borrar tabla temporal
  drop table #MedicosTemporal
end
go


-------------------------------------------------------------------------
--Importacion Datos Paciente
-------------------------------------------------------------------------
create or alter procedure esquemaPaciente.importarArchivoPacientes(
  @rutaArchivo varchar(2100)
)
as
begin
  create table #pacientesTemporal (
    nombre varchar(50) not null,
    apellido varchar(50) not null,
    fechaDeNacimiento varchar(20),
    tipoDocumento varchar(20),
    numeroDeDocumento int,
    sexoBiologico varchar(50),
    genero varchar(50),
    telefonoFijo varchar(50),
    nacionalidad char(50),
    mail varchar(100),
  calleYNro varchar(200),
    provincia varchar(50),
    localidad varchar(50)
  )

  declare @sqlPaciente nvarchar(1000) 
  set @sqlPaciente = '
    bulk insert #pacientesTemporal
    from ''' + @rutaArchivo + '''
    with
    (
      FIELDTERMINATOR = '';'',
      ROWTERMINATOR = ''\n'',
      CODEPAGE = ''ACP'',
      Firstrow = 2
    );
  '
  Exec sp_executesql @sqlPaciente

  -- Corregir campos
  update #pacientesTemporal 
  set nombre = esquemaPaciente.corregirCampo(nombre),
    apellido = esquemaPaciente.corregirCampo(apellido),
    tipoDocumento = esquemaPaciente.corregirCampo(tipoDocumento),
    sexoBiologico = esquemaPaciente.corregirCampo(sexoBiologico), 
    genero = esquemaPaciente.corregirCampo(genero),
    nacionalidad = esquemaPaciente.corregirCampo(nacionalidad), 
    mail = esquemaPaciente.corregirCampo(mail), 
    calleYNro = esquemaPaciente.corregirCampo(calleYNro),
  localidad= esquemaPaciente.corregirCampo(localidad),
  provincia=esquemaPaciente.corregirCampo(provincia)

/* Como en el archivo no se da la suficiente informacion para determinar concretamente el domicilio,
   consideramos que los domicilios son unicos. 
  Es decir, si 2 pacientes comparten la misma calle, numero, provincia
  y localidad, asumimos que viven en el mismo domicilio.*/
  insert into esquemaPaciente.domicilio(calle,localidad,provincia)
    select distinct calleYNro,localidad,provincia
    from #pacientesTemporal t
    where calleYNro not in (
                  select calle 
                    from esquemaPaciente.domicilio
                    where localidad=t.localidad and provincia=t.provincia
                )


  insert into esquemaPaciente.paciente(nombre,apellido,fechaDeNacimiento,tipoDocumento,numeroDeDocumento,
                    sexoBiologico,genero,telefonoFijo,nacionalidad,mail, idDomicilio) 
    select nombre,apellido,
        fechaDeNacimiento,
        tipoDocumento,
        numeroDeDocumento,
        sexoBiologico,
        genero,
        telefonoFijo,
        nacionalidad,
        mail,
        d.idDomicilio
    from #pacientesTemporal t
    inner join esquemaPaciente.domicilio d on d.calle= t.calleYNro
    where numeroDeDocumento not in (
                select numeroDeDocumento
                  from esquemaPaciente.paciente
                    )

  --Borrar tabla temporal
  drop table #pacientesTemporal
  end
go


-------------------------------------------------------------------------
-- Importacion de Archivo Prestador
-------------------------------------------------------------------------
create or alter procedure esquemaPaciente.importarArchivoPrestador (
    @rutaArchivo varchar(2100)
  )
  as
  begin
    create table #prestadorTemporal (
      nombrePrestador varchar(50),
      planPrestador varchar(50),
    )

    declare @sqlPrestador nvarchar(1000) 
    set @sqlPrestador = '
      bulk insert #prestadorTemporal
      from ''' + @rutaArchivo + '''
      with
      (
        FIELDTERMINATOR = '';'',
        ROWTERMINATOR = ''0x0A'',
        CODEPAGE = ''ACP'',
        Firstrow = 2
      );
    '
  --'\n'  '0x0A'
    Exec sp_executesql @sqlPrestador

    -- Corregir campos
    update #prestadorTemporal set 
    nombrePrestador = esquemaPaciente.corregirCampo(nombrePrestador),
    planPrestador = replace(esquemaPaciente.corregirCampo(planPrestador),';;','')

    --insert #sedeTemporal into esquemaSede.Sede
    insert into esquemaPaciente.prestador (nombrePrestador,planPrestador) 
    select nombrePrestador,planPrestador 
    from #prestadorTemporal
    where nombrePrestador not in (select p.nombrePrestador
                    from esquemaPaciente.prestador p
                    )
    --Borrar tabla temporal
    drop table #prestadorTemporal
  end
  go


-------------------------------------------------------------------------
-- Generacion de archivo XML
-------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE esquemaReserva.GenerarXMLTurnosAtendidos
    @NombreObraSocial NVARCHAR(50),
    @FechaInicio DATETIME,
    @FechaFin DATETIME
AS
BEGIN
    -- Obtener ID de la obra social
    DECLARE @ObraSocialID INT;
    SELECT @ObraSocialID = P.idPrestador
    FROM esquemaPaciente.prestador P
    WHERE P.idPrestador = @NombreObraSocial;

    -- Generar el XML
    SELECT
        PA.apellido AS 'Paciente/Apellido',
        PA.nombre AS 'Paciente/Nombre',
        PA.numeroDeDocumento AS 'Paciente/DNI',
        M.apellido AS 'Medico/Apellido',
        M.nombre AS 'Medico/Nombre',
        M.nroMatricula AS 'Medico/Matricula',
        RT.fecha AS 'Turno/Fecha',
        CONVERT(VARCHAR(8), RT.hora, 108) AS 'Turno/Hora',
        E.nombreEspecialidad AS 'Turno/Especialidad'
    FROM
        esquemaReserva.reservaDeTurnoMedico RT
        INNER JOIN esquemaPaciente.paciente PA ON RT.idHistoriaClinica = PA.idHistoriaClinica
        INNER JOIN esquemaPaciente.cobertura C ON PA.idCobertura = C.idCobertura
        INNER JOIN esquemaPaciente.prestador PR ON C.idPrestador = PR.idPrestador
        INNER JOIN esquemaMedico.medico M ON RT.idMedico = M.idMedico
        INNER JOIN esquemaMedico.especialidad E ON RT.idEspecialidad = E.idEspecialidad
    WHERE
        PR.idPrestador = @ObraSocialID
        AND RT.fecha BETWEEN @FechaInicio AND @FechaFin
    FOR XML PATH('Turno'), ROOT('Turnos');
END;