
id<-"<yourid>"
solepw<-"<yoursole_pwd>"
novapw<-"<yournova_pwd"



drv<-dbDriver("Oracle")
shost <- "<sole.full.path.to.server.gov>"
port <- port_number_here
ssid <- "<ssid_here>"

sole.connect.string<-paste(
  "(DESCRIPTION=",
  "(ADDRESS=(PROTOCOL=tcp)(HOST=", shost, ")(PORT=", port, "))",
  "(CONNECT_DATA=(SID=", ssid, ")))", sep="")
sole_conn<-dbConnect(drv, id, password=solepw, dbname=sole.connect.string)



nhost <- "nova.full.path.to.server.gov"
port <- port_number_here
ssid2 <- "<nova"

nova.connect.string<-paste(
  "(DESCRIPTION=",
  "(ADDRESS=(PROTOCOL=tcp)(HOST=", nhost, ")(PORT=", port, "))",
  "(CONNECT_DATA=(SID=", ssid2, ")))", sep="")
nova_conn<-dbConnect(drv, id, password=novapw, dbname=nova.connect.string)
