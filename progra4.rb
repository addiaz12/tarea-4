"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
"""""""""					Lenguajes de programación						    """""""""""""""""""""""""""""
"""""""""					Profesor: Andrei Fuentes Leiva						"""""""""""""""""""""""""""""
"""""""""					Adrián Díaz Meza									"""""""""""""""""""""""""""""
"""""""""					Alonso Vargas Astua 								"""""""""""""""""""""""""""""
"""""""""					John Largaespada P									"""""""""""""""""""""""""""""
"""""""""						    2012                                        """"""""""""""""""""""""""""" 
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""


#importamos las librerias necesarias
require 'cgi'
require 'rubygems'
require 'hpricot'
require 'open-uri'
require 'pp'
require "twitter"
require "oauth"

#clase menu, clase  Menu_principal, su obejetivo es facilitar la iteracción con el usuario
class Menu
 def menu
	puts "--------------------Band-Twit-----------------------"
	puts " @@@@                  @      @@@@@          @    @"
	puts " @   @  @@@@ @@@@   @@@@        @   @     @     @@@@@"
	puts " @@@@  @   @ @   @ @   @  @@@   @   @  @  @  @    @"
	puts " @   @ @  @@ @   @ @   @        @   @  @  @  @    @"
	puts " @@@@   @@ @ @   @  @@@@        @    @@ @@   @    @"
    puts "\n Digite el tag (género o ubicación)"
    url = "http://bandcamp.com/tag/" + gets
	nuevo = Extraer.new('http://bandcamp.com/')
	p nuevo.top10(url)
    Menu.new.menu
  end
end


#clase para extraer los datos necesarios de la pagina  http://bandcamp.com/
class Extraer

	def initialize(url)
	  @url = url;
	  @hp = Hpricot(open(@url))
	end
#Función recorre todo la pagina
	def recorre(url)
		array = []
		bandera = 0
		cont = 0
		open(url) do |f|
		  f.each do |line|
			  if line == "popularity\n"
				bandera = 1
			  end
			  if line == "                    .pager {\n"
				bandera = 2
			  end
			  if bandera == 1
				x = recorre_aux(line)
					if x != "vacio" and cont< 11
						array<<[x]
						cont = cont+1
					end
			  end 
		  end
		end
		return array
	end

	def recorre_aux(line)
		bandera1=0
		line.each_byte do |x|
			if  x == 97
				if bandera1 == 1
					return recorre_aux2(line)
					bandera1 = 0;
				end
			else
				bandera1 = 0
			end
			if x == 60
				bandera1 = 1
			end
		end
		return "vacio"
	end
	
#funcion q nos devuelve los link 
	def recorre_aux2(line)
		bandera1 = 0
		bandera2 = 0
		link = ""
		line.each_byte do |x|
			if x == 34 and bandera1 == 1
				return link
			end
			if bandera1 == 1
				link=link.concat(x.chr)		
			end
			if x == 34
				bandera1 = 1
			end
			
		end
	end
	

#Función para extraer los datos del autor
	def AutorAlbum(url)
	  url = url;
	  hp = Hpricot(open(url))
	  grupoAlbum = hp.at("meta[@name='title']")['content']
	  desglosa(grupoAlbum)
	end

	def desglosa(grupoAlbum)
		grupoAlbum = grupoAlbum.split(', by ')
		grupoAlbum
	end
	#Función para conocer si la canción es gratuito o no.			
	def costo(url)
		@link = url;
		@hp2 = Hpricot(open(@link))
		rating_text = (@hp2/"h4.compound-button").inner_text
		y="\n        \n          \n            Free Download\n          \n        \n        \n        \n    "
		if rating_text== y
			return "FREE"
		else	
			return"PAID"
		end
	end
#Funcion para almacenar los datos de cada uno de los datos que se extrajeron de la pagina.  	  
	def datos(url)
		x = AutorAlbum(url)
		nuevo_Album = Album.new
		nuevo_Album.set_Url(url)
		nuevo_Album.set_Album(x[0])
		nuevo_Album.set_Autor(x[1])
		nuevo_Album.set_Precio(costo(url))
#Llamada de la funcion Tweet para hacer los teewts en Tiwtter.		
		tw = Tweet.new
		tw.tweetear(url, x[0], x[1], costo(url))
	end

#Función para sacar los primeros 10 resultados que aparescan en la pagina.
	def top10(url)
		canciones = []
		lista=recorre(url)
		for i in 1..10
			puts "--------------------------------------------------------------"
			puts i
			datos(lista[i][0])
		end
	end
end


	

#clase que permite la autentificación en la cuenta de twitter
class Autentificar
  def initialize()
  @token="TY7zz27iEF1CWY0sjK1cA"
  @secret ="WV0J7FynkbpDAgsqSEhFcGK4lNqm4BnKHTTZWVfCs"
  end

#Función que permite la conexión, hace uso del mecanismo de autenticación OAuth, esto para que la cuenta no sea estatica
    def conection
      cliente=OAuth::Consumer.new(
      @token,
      @secret,
      {
        :site=>"http://twitter.com",
        :request_token_url=>"https://api.twitter.com/oauth/request_token",
        :access_token_url =>"https://api.twitter.com/oauth/access_token",
        :authorize_url    =>"https://api.twitter.com/oauth/authorize"
      }
    )
    #se solicita al api el token del usuario
    request_token = cliente.get_request_token
    token2 = request_token.token
    secret2 = request_token.secret   
    direccion = cliente.authorize_url + "?oauth_token=" + token2
    puts "" 
    puts "                          BIENVENIDO"
    puts "Acceda a la siguiente dirección y acepte la autorización de la aplicación: \n "
    puts direccion
    puts ""
    print "DIGITE EL PIN QUE APARECE EN EL BROWSER ===>  PIN:"
    pin = gets.chomp
	puts
	
    #se autentica al usuario de manera dinamica, esto con el uso de OAuth
    begin
      OAuth::RequestToken.new(cliente, token2, secret2)
      access_token=request_token.get_access_token(:oauth_verifier => pin)
      Twitter.configure do |config|
        config.consumer_key = @token
        config.consumer_secret = @secret
        config.oauth_token = access_token.token
        config.oauth_token_secret = access_token.secret
      end
      $client = Twitter::Client.new
      $client.verify_credentials
      puts "AUTENTICACIÓN EXITOSA"
      puts ""
      
	#validación si ocurriera algun problema en el proceso de autenticación
    rescue Twitter::Unauthorized
      puts "Error de Autorizacion"
    end
   end
end

#clase tweet
#Toma los datos extraidos de la pagina y los publica en Twitter
class Tweet

#Funcion que recibe los datos extraidos de la pagina, para twitear
  def tweetear(url, album, autor, precio)
  begin
    $client.update("URL: " + url + " Album: " + album + " Autor: " +  autor + " Precio: " +  precio)
  rescue Exception => e
    puts "Error: "+e.to_s
  end
end

end

#Creación de clases para cada uno de los metadatos extraidos
class Album
	attr_accessor:url
	attr_accessor:album
	attr_accessor:autor
	attr_accessor:precio
	
	
	def set_Url(nuevo_url)
		url = nuevo_url
		puts "URL ======> "+ url
	end
	
	def set_Album(nuevo_album)
		album = nuevo_album
		puts "Album ====> "+ album
	end
	
	def set_Autor(nuevo_autor)
		autor = nuevo_autor
		puts "Autor ====> "+ autor
	end
	
	def set_Precio(nuevo_precio)
		precio = nuevo_precio
		puts "Precio ===> "+ precio
	end
	
	def get_Album
		album
	end
	
	def get_Url
		url
	end
	
	def get_Autor
		autor
	end
	
	def get_precio
		precio
	end
	
end
	
#funcion inicial para ejecutar el programa
def main

  begin
    nuevo = Autentificar.new()
    nuevo .conection
    Menu.new.menu
  rescue => e
    puts "EROR: VUELVA A AUTENTIFICARSE"
    main
  end
end

main
