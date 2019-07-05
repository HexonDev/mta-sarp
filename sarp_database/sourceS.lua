local serverDatabase

addEventHandler("onResourceStart", getResourceRootElement(),
	function ()
		serverDatabase = dbConnect("mysql", "dbname=admin_mtasa;host=127.0.0.1;charset=utf8", "admin_mtasa", "72TTMLWXuw", "tag=sarpdb;multi_statements=1")
		
		if not serverDatabase then
			outputServerLog("[MySQL]: Failed to connect the database.")
			outputDebugString("[MySQL]: Sikertelen kapcsolódás az adatbázishoz!", 1)
			cancelEvent()
		else
			dbExec(serverDatabase, "SET NAMES utf8")
			outputDebugString("[MySQL]: Sikeres kapcsolódás az adatbázishoz.")
		end
	end
)

function getConnection()
	return serverDatabase
end