/*1. Análisis de ventas por género musical*/
/* Consulta para saber los 3 generos mas vendidos en las ventas historicas de la compañia*/

select top 3 g.Name, Sum(il.UnitPrice*il.Quantity) as Total_por_Genero
from Invoice i
join InvoiceLine il on i.InvoiceId = il.InvoiceId 
join Track t on t.TrackId = il.TrackId
join Genre g on g.GenreId = t.GenreId 
group by g.Name
order by Total_por_Genero Desc 

/* Consulta para saber los 3 generos menos vendidos en las ventas historicas de la compañia*/

select top 4 g.Name, Sum(il.UnitPrice*il.Quantity) as Total_por_Genero
from Invoice i
join InvoiceLine il on i.InvoiceId = il.InvoiceId 
join Track t on t.TrackId = il.TrackId
join Genre g on g.GenreId = t.GenreId 
group by g.Name
order by Total_por_Genero 

/*Visualizar que artistas y albumes son los del genero rock and roll*/

select ar.Name, a.Title
from Invoice i
join InvoiceLine il on i.InvoiceId = il.InvoiceId 
join Track t on t.TrackId = il.TrackId
join Genre g on g.GenreId = t.GenreId 
join Album a on t.AlbumId = a.AlbumId
join Artist ar on ar.ArtistId = a.ArtistId
where g.Name = 'Rock And Roll'
group by ar.Name, a.Title

/*2. Clientes top por país*/

/*¿Qué países tienen los clientes que más gastan?*/

Select top 5 a.Country, Sum(TotalGastado) as GastadoPorPais
from (select top 50 c.CustomerId, c.Country, Sum(il.UnitPrice*il.Quantity) AS TotalGastado
	from Customer C
	Join Invoice I on i.CustomerId = C.CustomerId
	Join InvoiceLine IL on il.InvoiceId = i.InvoiceId 
	group by c.CustomerId, c.Country
	order by TotalGastado Desc) as A
Group by a.Country
order by GastadoPorPais Desc

/*¿Cuáles son nuestros mejores clientes a nivel individual?*/

Select c.FirstName, c.LastName, C.Country,c.Email, BestClients.Gasto_Por_Cliente
From(
	select Top 10 c.CustomerId, SUM(il.UnitPrice*il.Quantity) as Gasto_Por_Cliente
	from Customer C
	Join Invoice I on i.CustomerId = C.CustomerId
	Join InvoiceLine IL on il.InvoiceId = i.InvoiceId 
	group by c.CustomerId
	Order by Gasto_Por_Cliente Desc) as BestClients
join Customer C on c.CustomerId = BestClients.CustomerId

/*3. Comparación de comportamiento por tipo de cliente*/

/*¿Hay diferencias en las compras entre países o regiones?*/

select sum(total) TotalGastado, BillingCity, BillingCountry, CompraRelacionPromedio = 
case 
	when sum(total) > (Select Avg(Totales)
						from (select sum(total) Totales, BillingCity
						from invoice
						group by BillingCity) as Regiones) then 'Mas que promeido'
	else 'Menos que el promedio'
end
from Invoice 
group by BillingCity, BillingCountry
order by TotalGastado desc,  BillingCountry, CompraRelacionPromedio

/*¿Qué tan seguido compran nuestros clientes más fieles?*/

Select top 15 FirstName,LastName,Country,MesesPromedioDeCompra
from Customer C
join (Select Top 15 CustomerId,  AVG(Promedio) as MesesPromedioDeCompra
from(select CustomerId, DATEDIFF(MONTH, InvoiceDate, (select max(InvoiceDate)	
											from Invoice)) as Promedio, Total
	from (select  c.CustomerId, i.InvoiceId, i.InvoiceDate, i.Total
		from InvoiceLine il
		join Invoice i on i.InvoiceId = il.InvoiceId
		join Customer C on C.CustomerId = i.CustomerId
		group by c.CustomerId, i.InvoiceId, i.InvoiceDate, i.Total
		having i.Total > (select avg(total)
						from Invoice)
		/*order by CustomerId, InvoiceDate*/) as ComprasClientesVIP
	/*order by CustomerId*/) as MesesPromedioMejoresCompras
group by MesesPromedioMejoresCompras.CustomerId) as PromedioMejoresClientes on c.CustomerId = PromedioMejoresClientes.CustomerId
order by MesesPromedioDeCompra


/*4. Análisis de artistas más rentables*/
/*¿Cuáles son los artistas que más ingresos nos generan?*/

Select Top 15 ar.Name, Sum(il.Quantity * il.UnitPrice) TotalVendido
from Invoice I
join InvoiceLine IL on i.InvoiceId = il.InvoiceId
join Track T on T.TrackId = il.TrackId
join Album Al on Al.AlbumId = T.AlbumId
join Artist Ar on Ar.ArtistId = Al.ArtistId
group by ar.Name
order by TotalVendido Desc

/*¿Coinciden con los más populares en cantidad de canciones vendidas?*/

/*Artistas con mas canciones vendidas*/

Select Top 15 Ar.Name, Sum(il.Quantity) CantidadesVendidas
from Invoice I
join InvoiceLine IL on i.InvoiceId = il.InvoiceId
join Track T on T.TrackId = il.TrackId
join Album Al on Al.AlbumId = T.AlbumId
join Artist Ar on Ar.ArtistId = Al.ArtistId
group by Ar.Name
order by CantidadesVendidas Desc

/*CANCIONES MAS VENDIDAS*/
Select Top 15 T.Name, SUM(il.Quantity) TotalVendido
from Invoice I
join InvoiceLine IL on i.InvoiceId = il.InvoiceId
join Track T on T.TrackId = il.TrackId
join Album Al on Al.AlbumId = T.AlbumId
join Artist Ar on Ar.ArtistId = Al.ArtistId
group by T.Name
order by TotalVendido Desc


/*5. Evaluación de desempeño de empleados de ventas*/

/*¿Qué empleados han gestionado clientes que compran más?*/

select distinct e.EmployeeId, FirstName, LastName, Country, Email
from Employee E
join (
select Top 5 e.EmployeeId, C.CustomerId, count(i.InvoiceId) FacturasRegistradas, sum(i.Total) TotalGastado
from Invoice I
join Customer C on i.CustomerId = C.CustomerId
Join Employee E on e.EmployeeId = c.SupportRepId
group by e.EmployeeId, C.CustomerId
order by TotalGastado Desc, EmployeeId) as MejoresEmpleados on e.EmployeeId = MejoresEmpleados.EmployeeId

/*¿Hay alguno que sobresalga en sus ventas?*/

select Top 1 e.EmployeeId, FirstName, LastName, Country, Email, MejoresVentas.TotalVendido
from Employee E
join (select e.EmployeeId, sum(i.Total) TotalVendido
from Invoice I
join Customer C on i.CustomerId = C.CustomerId
Join Employee E on e.EmployeeId = c.SupportRepId
group by e.EmployeeId) MejoresVentas on e.EmployeeId = MejoresVentas.EmployeeId
order by MejoresVentas.TotalVendido Desc


