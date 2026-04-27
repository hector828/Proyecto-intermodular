#!/bin/bash

id=$(id -u)
if (( $id != 0 ))
then
	echo "Tienes que ser administrador"
	exit 0
fi

echo "¿Que quieres hacer?"
echo "1 - Crear un usuario"
echo "2 - Crear un usuario en LDAP"
echo "3 - Borrar un usuario del sistema"
echo "4 - Borrar un elemento del ldap"
echo -n "Elige un numero:"
read opcion

case $opcion in
	1)
		echo "Creando un usuario"
        echo -n "Nombre de usuario:"
        read usuario
        echo -n "Grupo:"
        read grupo
        groupadd $grupo
        useradd $usuario -G $grupo -s /bin/bash -m -N
        echo "$usuario:$usuario" | chpasswd -c SHA512
        echo "Usuario $usuario creado quieres que este usuario tenga al sftp?"
        echo "1 - Si"
        echo "2 - No"
        echo -n "Elige un numero: "
        read sftp
        case $sftp in
            1)
                usermod -aG users-sftp $usuario
                mkdir /sftp/documentos/$usuario
                chown $usuario:users-ftp /sftp/documentos/$usuario
	        ;;
            *)
            ;;
        esac
    ;;
    2)
        echo "Creando un usuario en LDAP"
        dn="dc=arquitectotec,dc=es"
        sino=2
        while (( $sino != 1 ))
        do
            listado=$(ldapsearch -xLLL -b "$dn" | grep "dn" | awk '{print $2}')                
            numero=1
            echo "En que ruta quieres crear el usuario?"
            for i in $listado
            do
                echo -n "$numero - "
                echo $i
                ((numero++))
            done
            echo -n "Elige un numero: "
            read opcion
            numero=1
            for i in $listado
            do
                if [ $numero -eq $opcion ]
                then
                    dn=$i
                fi
                ((numero++))
            done
            echo "Quieres crear el usuario en $dn?"
            echo "1 - Si"
            echo "2 - No"
            echo -n "Elige un numero: "
            read sino
            ((veces++))
        done
        echo -n "Nombre de usuario:"
        read nombre
        echo -n "Numero de uid:"
        read uid
        echo -n "Numero de gid:"
        read gid
        echo "dn: $dn" > usuario.ldif
        echo "objectClass: top" >> usuario.ldif
        echo "objectClass: posixAccount" >> usuario.ldif
        echo "objectClass: inetOrgPerson" >> usuario.ldif
        echo "objectClass: person" >> usuario.ldif
        echo "cn: $nombre" >> usuario.ldif
        echo "uid: $nombre" >> usuario.ldif
        echo "ou: $grupo" >> usuario.ldif
        echo "uidNumber: $uid" >> usuario.ldif
        echo "gidNumber: $gid" >> usuario.ldif
        echo "homeDirectory: /home/$nombre" >> usuario.ldif
        echo "loginShell: /bin/bash" >> usuario.ldif
        echo -n "userPassword: " >> usuario.ldif
        slappasswd >> usuario.ldif
        echo "sn: $nombre" >> usuario.ldif
        echo "givenName: $nombre" >> usuario.ldif
    ;;
    3)
        echo "Borrando un usuario del sistema"
    ;;
    4)
        echo "Borrar un elemento del ldap"
    ;;
    *)
        echo "Opcion no valida"
    ;;
esac
