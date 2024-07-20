use COM5600G05
go

SET NOCOUNT ON;
go
-------------------------------------------------------------------------
--Store Procedures de la tabla Medico
-------------------------------------------------------------------------
create or alter procedure esquemaMedico.insertarMedico
(
    @nombre varchar(50),
    @apellido varchar(50),
    @nroMatricula int,
    @especialidad varchar(50)
)
as
begin
  -- Variable para concatenar los errores
  declare @mensajeError varchar(500)
  set @mensajeError = ''
  
  -- Se verifica si ya existe una medico con el mismo numero de matricula
  if not exists(select 1 from esquemaMedico.medico where nroMatricula = @nroMatricula)
  begin
  
  -- Se verifica que la especialidad exista
  declare @idEspecialidad int = -1

    select @idEspecialidad = idEspecialidad
    from esquemaMedico.especialidad
    where nombreEspecialidad = @especialidad

  -- Se verifica que las variables nombre y apellido no estén vacías
  if ( len(@nombre) = 0)
  begin
    set @mensajeError = @mensajeError + 'Error: Nombre o Apellido Vacío. '
  end

  if (@idEspecialidad <> -1 and len(@mensajeError) = 0)
    begin
      -- Si el medico y la especialidad existen, se hace el insert
      insert into esquemaMedico.medico (nombre, apellido, nroMatricula, idEspecialidad) 
      values (@nombre, @apellido, @nroMatricula, @idEspecialidad)
    end
  
  if @idEspecialidad=-1
    begin
      -- Si no existe la especialidad, retorna un mensaje de error
      set @mensajeError = @mensajeError + 'Error: No existe esa especialidad. '
    end
    
  end
  else
    begin
      -- Si ya existe el medico, retorna un mensaje de error
      set @mensajeError = @mensajeError + 'Error: Ya existe ese médico. '
    end

  -- En caso de haber un error
  if len(@mensajeError) <> 0
    RAISERROR(@mensajeError, 16, 1);
  return
end
go
--Ejemplo de Ejecucion:
--EXEC esquemaMedico.insertarMedico 'Juan', 'Perez', 12345, 'CARDIOLOGIA';

create or alter procedure esquemaMedico.eliminarMedico
(
  @nroMatricula int
)
as
begin
  if not exists( select 1 from esquemaMedico.medico where nroMatricula = @nroMatricula)
  begin
    RAISERROR('No existe el numero de matrícula ingresado', 16, 1);
    return;
  end
  
  update esquemaMedico.medico
  set activo = 0 -- Realizamos un borrado logico ya que existe una FK en la tabla reservaDeTurnoMedico
  where nroMatricula = @nroMatricula
end
go

--Ejemplo de Ejecucion:
--EXEC esquemaMedico.eliminarMedico 12345;

-------------------------------------------------------------------------
--Stored Procedures de Especialidad
-------------------------------------------------------------------------

create or alter procedure esquemaMedico.insertarEspecialidad(
  @nombreEspecialidad varchar(50)
  )
  as
  begin
  -- Se verifica si ya existe una especialidad con el mismo nombre
  if not exists (select 1 from esquemaMedico.especialidad where nombreEspecialidad = @nombreEspecialidad)
  begin

    -- Se verifica que el nombre de la especialidad pasado no esté vacío
    if (len(@nombreEspecialidad) = 0)
    begin
      RAISERROR('Nombre Vacío', 16, 1);
      return;
    end
      
    insert into esquemaMedico.especialidad (nombreEspecialidad) values (@nombreEspecialidad)
  end
  else
  begin
    -- Si ya existe, retorna un mensaje de error
    RAISERROR('Ya existe una especialidad con ese nombre.', 16, 1);
    return;
  end
end
go
--Ejemplo de Ejecucion:
--EXEC esquemaMedico.insertarEspecialidad 'CARDIOLOGIA';

-------------------------------------------------------------------------
--Store Procedures de DiasPorSede
-------------------------------------------------------------------------
create or alter procedure esquemaReserva.insertarDiasPorSede
(
  @idSede int,
  @idMedico int,
  @dia date,
  @horaInicio time,
  @horaFin time
)
as
begin
   -- Consideramos que el medico en un dia trabaja de seguido en una sola sede.
  if exists (select 1 from esquemaReserva.DiasPorSede where idMedico = @idMedico and dia = @dia)
  begin
      -- Si ya existe, retorna un mensaje de error
      RAISERROR('Ya existe un horario cargado para ese médico en la sede especificada.', 16, 1);
      return;
  end

  insert into esquemaReserva.diasPorSede (idSede,idMedico,dia,horaInicio, horaFin) 
  values (@idSede,@idMedico,@dia,@horaInicio,@horaFin)
end
go
--Ejemplo de Ejecucion:
--EXEC esquemaReserva.insertarDiasPorSede 1, 12345, '2024-06-14', '08:00', '17:00';

create or alter procedure esquemaReserva.actualizarDiasPorSede
(
  @idSede int,
  @idMedico int,
  @dia date,
  @horaInicio time,
  @horaFin time
)
as
begin
  -- Se verifica si ese medico trabaja en esa sede ese dia
  if exists (select 1 from esquemaReserva.DiasPorSede where idSede = @idSede and idMedico = @idMedico)
  begin
      update esquemaReserva.diasPorSede 
    set idMedico = @idMedico, dia = @dia,horaInicio = @horaInicio, horaFin = @horaFin 
    where idSede = @idSede
  end
  else
  begin
    -- Si los parametros de entrada son incorrectos, devuelve un error
    RAISERROR('El medico no trabaja en esa sede.', 16, 1);
    return;
  end
end
go
--Ejemplo de Ejecucion:
--EXEC esquemaReserva.actualizarDiasPorSede 1, 12345, '2024-06-14', '08:00', '16:00';

create or alter procedure esquemaReserva.eliminarDiasPorSede
(
  @idSede int,
  @idMedico int,
  @dia date
)
as
begin
  -- Se verifica si ese medico trabaja en esa sede ese dia
  if exists (select 1 from esquemaReserva.DiasPorSede where idSede = @idSede and idMedico = @idMedico and dia=@dia)
  begin
    -- Si ya existe, retorna un mensaje de error
    delete from esquemaReserva.diasPorSede where idSede=@idSede and idMedico=@idMedico and dia=@dia
  end
  else
  begin
    -- Si los parametros de entrada son incorrectos, devuelve un error
    RAISERROR('El medico no tiene horarios cargados en esa sede.', 16, 1);
    return;
  end
end
go

-------------------------------------------------------------------------
--Store Procedures de la tabla Sede
-------------------------------------------------------------------------
create or alter procedure esquemaSede.insertarSede
(
    @nombreSede varchar(100),
    @direccionSede varchar(200)
)
as
begin
    -- Se verifica si ya existe una sede con el mismo nombre
    if exists (select 1 from esquemaSede.sede where nombreSede = @nombreSede and direccionSede = @direccionSede)
    begin
        -- Si ya existe, retorna un mensaje de error
        RAISERROR('Ya existe una sede con el nombre especificado.', 16, 1);
        return;
    end

    -- Se verifica que el nombre de la sede y la dirección no estén vacíos
    if (len(@nombreSede) = 0 or len(@direccionSede) = 0)
    begin
      RAISERROR('Nombre o Dirección Vacíos', 16, 1);
      return;
    end

    -- Si no existe, se hace la inserción
  insert into esquemaSede.sede (nombreSede,direccionSede) values (@nombreSede,@direccionSede)
end
go

create or alter procedure esquemaSede.eliminarSede
(
    @idSede int
)
as
begin
    if exists (select 1 from esquemaSede.Sede where idSede = @idSede)
    begin
        update esquemaSede.sede
        set activo = 0 -- Borrado logico para no romper las reservas
        where idSede = @idSede
    end
  else
  begin
    -- Si los parametros de entrada son incorrectos, devuelve un error
    RAISERROR('No existe una sede con el ID ingresado.', 16, 1);
    return;
  end
end
go

create or alter procedure esquemaSede.actualizarSede
(
    @nombreSede varchar(100),
    @direccionSede varchar(200)
)
as
begin
    if not exists( select 1 from esquemaSede.sede where nombreSede = @nombreSede)
    begin
      RAISERROR('No existe la sede ingresada', 16, 1);
      return;
    end
    
    update esquemaSede.sede
    set
        nombreSede = @nombreSede,
        direccionSede = @direccionSede
    where nombreSede=@nombreSede
end
go

-------------------------------------------------------------------------
--Store Procedures de la tabla Tipo de Turno
-------------------------------------------------------------------------
create or alter procedure esquemaReserva.insertarTipoTurno(
      @nombreTipoTurno varchar(50)
)
as
begin
   if exists(select 1 from esquemaReserva.tipoTurno where nombreDelTipoDeTurno = @nombreTipoturno)
  begin
      -- Si ya existe, retorna un mensaje de error
      RAISERROR('Ya existe un Tipo de Turno con el nombre especificado.', 16, 1);
      return;
  end

  -- Se verifica que el nombre del tipo de turno no esté vacío
  if (len(@nombreTipoturno) = 0)
  begin
    RAISERROR('Tipo de turno vacío', 16, 1);
  end
    
    insert into esquemaReserva.tipoTurno (nombreDelTipoDeTurno) values (@nombreTipoTurno)
end
go

create or alter procedure esquemaReserva.actualizarTipoTurno(
  @nombreTipoTurnoViejo varchar(50),
  @nombreTipoTurnoNuevo varchar(50)
)
as
begin
  if exists(select 1 from esquemaReserva.tipoTurno where nombreDelTipoDeTurno = @nombreTipoTurnoViejo)
  begin
    update esquemaReserva.tipoTurno 
    set 
    nombreDelTipoDeTurno = @nombreTipoTurnoNuevo
    where nombreDelTipoDeTurno = @nombreTipoTurnoViejo
  end
end
go

-------------------------------------------------------------------------
--Store Procedures de la tabla Estado de Turno
-------------------------------------------------------------------------
create or alter procedure esquemaReserva.insertarEstadoTurno
(
  @nombreEstado varchar(50)
)
as
begin
    if (len (@nombreEstado) = 0)
    begin
        RAISERROR('Nombre de Estado vacío.', 16, 1);
        return;
    end
  
  if exists (select 1 from esquemaReserva.estadoTurno where nombreEstado = @nombreEstado)
  begin
      -- Si ya existe, retorna un mensaje de error
      RAISERROR('Ya existe un estado con el nombre especificado.', 16, 1);
      return;
  end
  insert into esquemaReserva.estadoTurno (nombreEstado) values (@nombreEstado)
end
go

create or alter procedure esquemaReserva.actualizarEstadoTurno
(
  @nombreEstadoViejo varchar(50),
  @nombreEstadoNuevo varchar(50)
)
as
begin
  if exists (select 1 from esquemaReserva.estadoTurno e where e.nombreEstado = @nombreEstadoViejo)
  begin
      -- Si existe, modifica el registro
      update esquemaReserva.estadoTurno 
    set 
    nombreEstado=@nombreEstadoNuevo 
    where nombreEstado=@nombreEstadoViejo
  end
end
go

-------------------------------------------------------------------------
--Store Procedures de la tabla Domicilio
-------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE esquemaPaciente.insertarDomicilio
(
  @calle varchar(50),
  @departamento int,
  @codigoPostal varchar(50),
  @pais varchar(50),
  @provincia varchar(50),
  @localidad varchar(50)
)
AS
BEGIN
  --Variable para concatenar los errores
  declare @mensajeError varchar(500)
  set @mensajeError = ''
    
  -- Se verifica que los parámetros son válidos
  IF @departamento <= 0
      set @mensajeError= @mensajeError + 'Error: El valor de departamento debe ser mayor que 0. '

  -- Verificar si ya existe el domicilio
  IF EXISTS (SELECT 1 
             FROM esquemaPaciente.domicilio 
             WHERE calle = @calle 
               AND departamento = @departamento 
               AND codigoPostal = @codigoPostal 
               AND pais = @pais 
               AND provincia = @provincia 
               AND localidad = @localidad)
      -- Si ya existe, retorna un mensaje de error
      set @mensajeError = @mensajeError + 'Error: Ya existe un domicilio cargado con esos datos. '

  -- Se verifica que calle no esté vacío
  if (len(@calle) = 0)
    set @mensajeError = @mensajeError + 'Error: Calle Vacía. '

  if (len(@mensajeError) <> 0)
  begin
    RAISERROR(@mensajeError, 16, 1);
    return;
  end

  -- Insertar el nuevo domicilio
  INSERT INTO esquemaPaciente.domicilio (calle,departamento, codigoPostal, pais, provincia, localidad) 
  VALUES (@calle,@departamento, @codigoPostal, @pais, @provincia, @localidad);
END
GO

create or alter procedure esquemaPaciente.actulizarDomicilio
(
  @idDomicilio int,
  @calle varchar(50),
  @departamento int,
  @codigoPostal varchar(50),
  @pais varchar(50),
  @provincia varchar(50),
  @localidad varchar(50)
)
as
begin
  IF @departamento <= 0
    BEGIN
      RAISERROR('El valor de departamento debe ser mayor que 0.', 16, 1);
      RETURN;
    END

  if exists (select 1 from esquemaPaciente.domicilio where idDomicilio=@idDomicilio)
  begin
    update esquemaPaciente.domicilio 
  set calle = @calle, departamento = @departamento, codigoPostal = codigoPostal, pais = @pais, provincia = @provincia, localidad = @localidad
  end
end
go

-------------------------------------------------------------------------
--Store Procedures de la tabla usuarios
-------------------------------------------------------------------------
create or alter procedure esquemaPaciente.insertarUsuario
(
    @contraseña varchar(50)
)
as
begin
      -- Se verifica que contraseña no esté vacío
      if (len(@contraseña) = 0)
      begin
        RAISERROR('Contraseña Vacía', 16, 1);
        return;
      end
    insert into esquemaPaciente.usuario (contraseña) values (@contraseña)
end
go

create or alter procedure esquemaPaciente.actualizarUsuario
(
  @idUsuario int,
  @contraseña varchar(50)
)
as
begin
      if exists (select 1 from esquemaPaciente.usuario where idUsuario = @idUsuario)
        begin
            -- Si existe, modifica el registro
            update esquemaPaciente.usuario 
        set contraseña = @contraseña
        where idUsuario = @idUsuario
        end
      else
        BEGIN
          RAISERROR('El usuario insertado no existe.', 16, 1);
          RETURN;
        END
end
go
/* Aclaracion: Consideramos que no hace falta hacer un store procedure 
para eliminar usuarios. */

-------------------------------------------------------------------------
--Store Procedures de Prestador
-------------------------------------------------------------------------
create or alter procedure esquemaPaciente.insertarPrestador(
  @nombrePrestador varchar(50),
  @planPrestador varchar(50)
)
as
begin
  if not exists(select 1 from esquemaPaciente.prestador where nombrePrestador = @nombrePrestador and planPrestador = @planPrestador)
  begin

    -- Se verifica que el nombre del prestador y el plan no estén vacíos
    if (len(@nombrePrestador) = 0 or len(@planPrestador) = 0)
    begin
      RAISERROR('Nombre de Prestador o Plan de Prestador Vacíos', 16, 1);
      return;
    end
          
    insert into esquemaPaciente.prestador
      (nombrePrestador,planPrestador) values
      (@nombrePrestador,@planPrestador)
  end
  else
  begin
    -- Si ya existe, devuelve un error
    RAISERROR('Ya existe un prestado con los datos ingresados.', 16, 1);
    return;
  end
end
go

create or alter procedure esquemaPaciente.actualizarPrestador(
  @idPrestador int,
  @nombrePrestador varchar(50),
  @planPrestador varchar(50)
)
as
begin
  if exists(select 1 from esquemaPaciente.prestador where idPrestador = @idPrestador)
  begin
    update esquemaPaciente.prestador
    set 
    nombrePrestador = @nombrePrestador,
    planPrestador = @planPrestador
    where idPrestador = @idPrestador
  end
  else
    BEGIN
      RAISERROR('El prestador ingresado no existe.', 16, 1);
      RETURN;
    END
end
go

create or alter procedure esquemaPaciente.eliminarPrestador(
  @idPrestador int
)
as
begin
  if exists(select 1 from esquemaPaciente.prestador where idPrestador = @idPrestador)
  begin
  update esquemaPaciente.prestador
  set activo=0
  where idPrestador=@idPrestador

  update esquemaPaciente.cobertura
  set activo=0
  where idCobertura in (select c.idCobertura
        from esquemaPaciente.cobertura c inner join esquemaPaciente.prestador p
        on c.idPrestador=p.idPrestador
        where c.idPrestador=@idPrestador
        )

  update esquemaPaciente.paciente
  set activo=0
  where idHistoriaClinica in (select p.idHistoriaClinica
        from esquemaPaciente.cobertura c 
        inner join esquemaPaciente.paciente p on c.idCobertura=p.idCobertura
        where c.idPrestador=@idPrestador
        );

  with CTE 
  as
  (
    select r.idEstadoTurno
    from [esquemaPaciente].[cobertura] c
    inner join esquemaPaciente.prestador p on c.idPrestador =p.idPrestador
    inner join esquemaPaciente.paciente pa on c.idCobertura =pa.idCobertura
    inner join [esquemaReserva].[reservaDeTurnoMedico] r on pa.idHistoriaClinica = r.idHistoriaClinica
    where p.idPrestador= @idPrestador
  )
  update CTE 
    set idEstadoTurno=( select e.idEstadoTurno 
              from esquemaReserva.estadoTurno e 
              where e.nombreEstado='CANCELADO')

  end
  else
  begin
    -- Si no existe, devuelve un error
    RAISERROR('No existe un prestador con el ID ingresado.', 16, 1);
    return;
  end
end
go

-------------------------------------------------------------------------
--Store Procedures de Cobertura
-------------------------------------------------------------------------
create or alter procedure esquemaPaciente.insertarCobertura(
  @imagenCredencial varchar(2100),
  @nroSocio int,
  @fechaIngreso datetime,
  @idPrestador int
)
  as
  begin
  if not exists(select 1 from esquemaPaciente.cobertura where
    idPrestador = @idPrestador and nroSocio = @nroSocio)
  begin
  insert into esquemaPaciente.cobertura (imagenCredencial, nroSocio, fechaIngreso, idPrestador) 
    values (@imagenCredencial, @nroSocio, @fechaIngreso, @idPrestador)
  end
  else
  begin
    -- Si ya existe, devuelve un error
    RAISERROR('Ya existe una cobertura con ese numero de socio.', 16, 1);
    return;
  end
end
go

-- Ejemplo de Ejecucion: exec actualizarCobertura @imagenCredencial, @nroSocio, @fechaIngreso, @idPrestador
create or alter procedure esquemaPaciente.actualizarCobertura (
  @idCobertura int,
  @imagenCredencial varchar(2100),
  @nroSocio int,
  @fechaIngreso datetime,
  @idPrestador int
      -- Consideramos que para actualizar la cobertura tiene que pasar todos los campos del registro
)
  as
  begin
  if not exists(select 1 from esquemaPaciente.cobertura where
      idCobertura = @idCobertura)
  begin
    -- Si ya existe, retorna un mensaje de error
    RAISERROR('No existe la cobertura solicitada.', 16, 1);
    return;
  end
    insert into esquemaPaciente.cobertura (imagenCredencial, nroSocio, fechaIngreso, idPrestador) values (@imagenCredencial, @nroSocio, @fechaIngreso, @idPrestador)
end
go

create or alter procedure esquemaPaciente.eliminarCobertura (
  @idCobertura int
)
as
begin
  if exists (select 1 from esquemaPaciente.cobertura where idCobertura = @idCobertura)
  begin
  update esquemaPaciente.cobertura 
    set Activo = 0 
    where idCobertura = @idCobertura;
  end
  else
  begin
    -- Si no existe, devuelve un error
    RAISERROR('No existe una cobertura con el ID ingresado.', 16, 1);
    return;
  end
end;
go

-------------------------------------------------------------------------
--Store Procedures de Paciente
-------------------------------------------------------------------------
create or alter procedure esquemaPaciente.insertarPaciente (
    @nombre varchar(50),
    @apellido varchar(50),
    @apellidoMaterno varchar(50),
    @fechaDeNacimiento datetime,
    @tipoDocumento varchar(20),
    @numeroDeDocumento int,
    @sexoBiologico varchar(50),
    @genero varchar(50),
    @nacionalidad char(50),
    @fotoDePerfil char(2100),
    @mail varchar(100),
    @telefonoFijo varchar(50),
    @telefonoDeContactoAlternativo varchar(50),
    @telefonoLaboral varchar(50),
    @fechaDeRegistro datetime,
    @fechaDeActualizacion datetime,
    @usuarioActualizacion int,
    @idUsuario int,
    @idCobertura int,
    @idDomicilio int
    )
    as
    begin
    -- Se verifica que los strings pasados no estén vacíos
    if (len(@apellido) = 0 or len(@tipoDocumento) = 0 or len(@sexoBiologico) = 0 or len(@genero) = 0
  or len(@nacionalidad) = 0 or len(@mail) = 0 or len(@telefonoFijo) = 0)
    begin
      RAISERROR('Apellido, Tipo de Documento, sexo biológico, género, nacionalidad, mail o telefono fijo Vacíos', 16, 1);
      return;
    end
      
    if not exists(select 1 from esquemaPaciente.paciente where
      numeroDeDocumento = @numeroDeDocumento and tipoDocumento = @tipoDocumento)
    begin
      insert into esquemaPaciente.paciente 
    (nombre, apellido, apellidoMaterno, fechaDeNacimiento,tipoDocumento, 
    numeroDeDocumento, sexoBiologico, genero, nacionalidad,fotoDePerfil,
    mail, telefonoFijo,telefonoDeContactoAlternativo, 
    telefonoLaboral, fechaDeRegistro, fechaDeActualizacion, 
    usuarioActualizacion, idUsuario, idCobertura,idDomicilio) 
    values (@nombre, @apellido, @apellidoMaterno, @fechaDeNacimiento,@tipoDocumento, 
    @numeroDeDocumento, @sexoBiologico, @genero, @nacionalidad,@fotoDePerfil,
    @mail, @telefonoFijo, @telefonoDeContactoAlternativo, 
    @telefonoLaboral, @fechaDeRegistro, @fechaDeActualizacion, 
    @usuarioActualizacion, @idUsuario, @idCobertura, @idDomicilio)  
    end
  else
  begin
    -- Si ya existe, devuelve un error
    RAISERROR('Ya existe un paciente con el tipo y numero de documento ingresado.', 16, 1);
    return;
  end
  end
go

create or alter procedure esquemaPaciente.eliminarPaciente(
  @idPaciente int
)
as
begin
  if exists(select 1 from esquemaPaciente.paciente where idHistoriaClinica = @idPaciente)
  begin
  update esquemaPaciente.paciente 
    set activo = 0
    where [idHistoriaClinica] = @idPaciente
  end
  else
  begin
    -- Si no existe, devuelve un error
    RAISERROR('El medico no trabaja en esa sede.', 16, 1);
    return;
  end
end
go

-------------------------------------------------------------------------
--Store Procedures de Estudio
-------------------------------------------------------------------------
create or alter procedure esquemaPaciente.insertarEstudio(
    @fecha datetime,
    @nombreEstudio varchar(50),
    @documentoResultado char(2100),
    @autorizado bit,
    @imagenResultado char(2100),
    @idHistorialClinico int
)
as
begin

    -- Se verifica que el nombre del estudio no esté vacío
    if (len(@nombreEstudio) = 0)
    begin
      RAISERROR('Nombre de Estudio Vacío', 16, 1);
      return;
    end
    
    if not exists(select 1 from esquemaPaciente.estudio where fecha = @fecha and idHistorialClinico = @idHistorialClinico)
    begin
      insert into esquemaPaciente.estudio (fecha,nombreEstudio,documentoResultado,autorizado,imagenResultado,idHistorialClinico) 
    values (@fecha,@nombreEstudio,@documentoResultado, @autorizado, @imagenResultado,@idHistorialClinico)
    end
    else
  begin
    -- Si ya existe, devuelve un error
    RAISERROR('El a insertar ya existe.', 16, 1);
    return;
  end
end
go

create or alter procedure esquemaPaciente.actualizarCoberturaPaciente(
  @idHistoriaClinica int,
  @idCobertura int
)
as
begin
  update esquemaPaciente.paciente
    set idCobertura=@idCobertura
    where idHistoriaClinica=@idHistoriaClinica
end
go

-------------------------------------------------------------------------
--Store Procedures de Reserva
-------------------------------------------------------------------------
create or alter procedure esquemaReserva.insertarReserva(
  @fecha date,
  @hora time,
  @idMedico int,
  @idHistoriaClinica int
)
as
begin
  --Variable para concatenar los errores
  declare @mensajeError varchar(500)
  set @mensajeError = ''

  -- Verificacion para no insertar reservas repetidas
  if exists(select 1 from esquemaReserva.reservaDeTurnoMedico 
      where fecha = @fecha and hora = @hora and idMedico = @idMedico and 
          idEstadoTurno <> (select idEstadoTurno from esquemaReserva.estadoTurno where nombreEstado='CANCELADO'))
  begin
    -- Si ya existe, retorna un mensaje de error
    set @mensajeError = @mensajeError + 'Error: La reserva que se quiere insertar esta duplicada. ';
  end

  --Verificacion de paciente activo
   if exists(select 1 from esquemaPaciente.paciente where idHistoriaClinica=@idHistoriaClinica and activo=0)
  begin
    -- Si ya existe, retorna un mensaje de error
    set @mensajeError = @mensajeError + 'Error: El paciente no esta activo y no puede reservar turnos. ';
  end

  -- Verificacion para validar el medico en esa fecha, hora y lugar
  if not exists(select 1 from esquemaReserva.diasPorSede where dia = @fecha and @hora between horaInicio and HoraFin and idMedico = @idMedico)
  begin
    -- Si la informacion del medico es incorrecta
    set @mensajeError = @mensajeError + 'Error: La reserva que se quiere insertar incluye datos inconsistentes. '
  end

  if (len(@mensajeError) <> 0)
  begin
    RAISERROR(@mensajeError, 16, 1);
    return;
  end
    
    insert into esquemaReserva.reservaDeTurnoMedico  
    (fecha, hora, idMedico, idEspecialidad, idDireccionAtencion,
    idTipoTurno, idHistoriaClinica,idEstadoTurno)
  select @fecha, @hora, @idMedico, m.idEspecialidad,d.idSede,1,@idHistoriaClinica, 
    (select idEstadoTurno 
      from esquemaReserva.estadoTurno 
      where nombreEstado='DISPONIBLE')
    from esquemaReserva.diasPorSede d
    inner join esquemaMedico.medico m on m.idMedico=@idMedico
    where d.idMedico=@idMedico and d.dia=@fecha
end
Go

create or alter procedure esquemaReserva.cancelarReserva(
  @idTurno int
)
as
begin
  -- Verificacion para buscar la reserva
  if not exists(select 1 from esquemaReserva.reservaDeTurnoMedico where idTurno = @idTurno)
  begin
    -- Si no existe, retorna un mensaje de error
    RAISERROR('La reserva que se quiere actualizar no existe.', 16, 1);
    return;
  end

  update esquemaReserva.reservaDeTurnoMedico 
  set idEstadoTurno=(select idEstadoTurno
              from esquemaReserva.estadoTurno
              where nombreEstado='CANCELADO'
            )
  where idTurno=@idTurno
end
go