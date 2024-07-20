use COM5600G05
go

-------------------------------------------------------------------------
--Insertar datos de Medicos
-------------------------------------------------------------------------

exec esquemaMedico.importarArchivoMedicos 'Dataset\Medicos.csv' 

select * from esquemaMedico.medico

--Si no estan insertadas esas especialidades se insertan.
select * from esquemaMedico.especialidad

-------------------------------------------------------------------------
--Insertar datos de Sedes
-------------------------------------------------------------------------
exec esquemaSede.importarArchivoSedes 'Dataset\Sedes.csv'

select * from esquemaSede.sede

-------------------------------------------------------------------------
--Insertar datos de Prestadores
-------------------------------------------------------------------------
exec esquemaPaciente.importarArchivoPrestador 'Dataset\Prestador.csv'

select * from esquemaPaciente.prestador
  
-------------------------------------------------------------------------
--Insertar datos de Pacientes
-------------------------------------------------------------------------
exec esquemaPaciente.importarArchivoPacientes 'Dataset\Paciente.csv'

select * from esquemaPaciente.paciente

--Si no estan insertadas los domicilios se insertan.

select * from esquemaPaciente.domicilio

-------------------------------------------------------------------------
--Insertar datos de Autorizaciones Estudios clínicos
-------------------------------------------------------------------------
exec esquemaPaciente.importarAutorizaciones 'Dataset\Centro_Autorizaciones.Estudios clinicos.json'

select * from esquemaPaciente.autorizaciones

-------------------------------------------------------------------------
--Insertar datos de Turno
-------------------------------------------------------------------------
select * from esquemaReserva.estadoTurno
exec esquemaReserva.insertarEstadoTurno 'DISPONIBLE'
exec esquemaReserva.insertarEstadoTurno 'CANCELADO'

select * from esquemaReserva.tipoTurno
exec esquemaReserva.insertarTipoTurno 'PRESENCIAL'
exec esquemaReserva.insertarTipoTurno 'VIRTUAL'

-------------------------------------------------------------------------
--Insertar dias por Sede
-------------------------------------------------------------------------
exec esquemaReserva.insertarDiasPorSede 1,2,'10-06-2024','9:00','21:00' --Medico con ID:2 y sede ID:1
exec esquemaReserva.insertarDiasPorSede 1,3,'10-06-2024','7:00','15:00' --Medico con ID:3 y sede ID:1
exec esquemaReserva.insertarDiasPorSede 2,4,'10-06-2024','8:00','20:00' --Medico con ID:4 y sede ID:2
exec esquemaReserva.insertarDiasPorSede 2,5,'10-06-2024','9:00','18:00' --Medico con ID:5 y sede ID:2

-------------------------------------------------------------------------
--Insertar Reservas
-------------------------------------------------------------------------
exec esquemaReserva.insertarReserva '10-06-2024','14:15',2,50 --fecha-hora-medico-Paciente
exec esquemaReserva.insertarReserva '10-06-2024','14:45',2,49
exec esquemaReserva.insertarReserva '10-06-2024','10:45',2,40
exec esquemaReserva.insertarReserva '10-06-2024','9:45',2,45

--Mensaje de Error
exec esquemaPaciente.eliminarPaciente 45
exec esquemaReserva.insertarReserva '10-06-2024','6:45',2,45

--Mas Ingresos de Reservas
exec esquemaReserva.insertarReserva '10-06-2024','14:15',3,54 --fecha-hora-medico-Paciente
exec esquemaReserva.insertarReserva '10-06-2024','14:45',3,53
exec esquemaReserva.insertarReserva '10-06-2024','10:45',3,41
exec esquemaReserva.insertarReserva '10-06-2024','7:45',3,46
  
-------------------------------------------------------------------------
--Insertar Cobertura
-------------------------------------------------------------------------
exec esquemaPaciente.insertarCobertura 'https:',50006,'10-06-2020',1 --imagen-nroSocio-fechaIngreso-idPrestador
exec esquemaPaciente.insertarCobertura 'https:',50007,'10-06-2020',2
exec esquemaPaciente.insertarCobertura 'https:',50008,'10-06-2020',3
exec esquemaPaciente.insertarCobertura 'https:',50009,'10-06-2020',4
exec esquemaPaciente.insertarCobertura 'https:',500010,'10-06-2020',1
exec esquemaPaciente.insertarCobertura 'https:',50011,'10-06-2020',2
exec esquemaPaciente.insertarCobertura 'https:',500012,'10-06-2020',3
exec esquemaPaciente.insertarCobertura 'https:',500013,'10-06-2020',4

select * from esquemaPaciente.cobertura

-------------------------------------------------------------------------
--Asociar cobertura a un paciente
-------------------------------------------------------------------------
exec esquemaPaciente.actualizarCoberturaPaciente 54,1 --paciente -- IDCobertura
exec esquemaPaciente.actualizarCoberturaPaciente 53,2
exec esquemaPaciente.actualizarCoberturaPaciente 50,3 
exec esquemaPaciente.actualizarCoberturaPaciente 49,4
exec esquemaPaciente.actualizarCoberturaPaciente 46,5
exec esquemaPaciente.actualizarCoberturaPaciente 45,6
exec esquemaPaciente.actualizarCoberturaPaciente 41,7 
exec esquemaPaciente.actualizarCoberturaPaciente 40,8

select * from esquemaPaciente.paciente
select * from esquemaReserva.reservaDeTurnoMedico

-------------------------------------------------------------------------
--Eliminar prestador (borrado en cascada hasta reserva)
-------------------------------------------------------------------------
exec esquemaPaciente.eliminarPrestador 1

select * from esquemaPaciente.prestador
select * from esquemaPaciente.cobertura
select * from esquemaPaciente.paciente
select * from esquemaReserva.reservaDeTurnoMedico

-------------------------------------------------------------------------
--Cancelar (borrado en cascada)
-------------------------------------------------------------------------
exec esquemaReserva.cancelarReserva 4

select * from esquemaReserva.reservaDeTurnoMedico

-------------------------------------------------------------------------
--Reservar en fecha cancelada
-------------------------------------------------------------------------
exec esquemaReserva.insertarReserva '10-06-2024','9:45',2,40

select * from esquemaReserva.reservaDeTurnoMedico

-------------------------------------------------------------------------
--Generar archivo XML
-------------------------------------------------------------------------
exec esquemaReserva.GenerarXMLTurnosAtendidos 1,'10-06-2020','10-06-2025'

-------------------------------------------------------------------------
--Insertar Medico Sin Nombre
-------------------------------------------------------------------------
exec esquemaMedico.insertarMedico " "," ",12,"ALERGIA"

select * from esquemaMedico.Medico
	where nroMatricula=12

-------------------------------------------------------------------------
--Insertar Domicilio Sin Nombre
-------------------------------------------------------------------------
exec esquemaPaciente.insertarDomicilio " ",0,"1111","Arg"," "," "

exec esquemaPaciente.insertarDomicilio "ALLE 11",NULL,NULL,	NULL,"CITY BELL","BUENOS AIRES"

select * from esquemaPaciente.domicilio
