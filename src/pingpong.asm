; ==========================================================================
; KONAMI'S PING PONG - Konami - MSX1 - cartucho RC-731 de 16 KB en la pagina 1
; ==========================================================================
; Generado por tools/mkasm.py a partir del trazado de flujo real.
; Los comentarios provienen de tools/../src/*.notes y estan anclados a
; direccion, de modo que sobreviven a un retrazado.
; ==========================================================================

	org 0x04000


; ----------------------------------------------------------------------
; Direcciones que solo aparecen como VALOR -en un `ld`, no en
; un salto-: son punteros que el codigo se pasa o numeros que
; casualmente coinciden con una direccion. No hay nada que
; trazar en ellas; el equ existe para que el listado ensamble.
; ----------------------------------------------------------------------
l404eh:	equ 0x0404e

; ----------------------------------------------------------------------
; DATOS cabecera_del_cartucho: "AB" y la direccion de INIT (0x406C);
;   STATEMENT, DEVICE y TEXT a cero, y los seis bytes reservados tambien
;   0x4000..0x4010  (16 bytes)
DATA_cabecera_del_cartucho:
	defw 04241h,0406ch,00000h,00000h,00000h,00000h,00000h,00000h	; 4000

; ======================================================================
; CODIGO 0x4010..0x40c9  (185 bytes)
; ======================================================================


L_4010:
	ld a,(l404eh)		;4010   ; lee un byte de la propia ROM
	ld (040eeh),a		;4013   ; y lo escribe en otra direccion de la propia ROM, que no admite escritura: no llega a ninguna parte
	jp carga_los_patrones_del_titulo		;4016   ; y sigue con los patrones del rotulo

; ----------------------------------------------------------------------
; ===== EL LATIDO: el gancho de la interrupcion =====
; ----------------------------------------------------------------------
latido:		; H.KEYI: todo el juego cuelga de aqui, una vez por cuadro
	call 0013eh		;4019   ; BIOS RDVDP - Reads VDP status register | RDVDP: leer el estado del VDP es lo que ACEPTA la interrupcion
	di			;401c   ; a partir de aqui, la interrupcion cerrada
	call late_el_sonido		;401d   ; con la interrupcion cerrada, el sonido: es lo unico que no puede perder un cuadro
	ld hl,0e005h		;4020   ; (0xE005) es el cerrojo de reentrada
	bit 0,(hl)		;4023   ; si ya hay un cuadro dentro, no se entra otra vez
	jr nz,L_4045		;4025   ; con el cerrojo echado se salta el cuadro entero
	inc (hl)			;4027   ; echa el cerrojo
	ei			;4028   ; y lo demas ya puede correr con la interrupcion abierta
	call mira_cambio_de_campo		;4029   ; mira si toca cambiar de campo
	ld a,(0e04bh)		;402c   ; (0xE04B): el aviso de que hay trabajo pendiente de VRAM
	and a			;402f   ; cero es que no hay nada pendiente
	call nz,intercambia_los_mandos		;4030   ; solo si lo hay
	call lee_los_mandos		;4033   ; el grueso del cuadro
	ld a,(0e04bh)		;4036   ; (0xE04B) otra vez
	and a			;4039   ; y otra vez a cero es que no hay nada
	call nz,intercambia_los_mandos		;403a   ; se vuelve a mirar, porque el grueso ha podido dejar mas trabajo
	call corre_la_escena		;403d   ; y por ultimo la escena que toque
	ld a,000h		;4040   ; cero en A
	ld (0e005h),a		;4042   ; suelta el cerrojo
L_4045:
	call 0013eh		;4045   ; BIOS RDVDP - Reads VDP status register | segunda lectura del estado del VDP
	or a			;4048   ; el bit 7 es el aviso de interrupcion
	di			;4049   ; la lectura del estado se hace con la interrupcion cerrada
	call m,late_el_sonido		;404a   ; si estaba puesto, otra pasada de sonido
	ei			;404d   ; y se vuelve a abrir
L_404E:
	ret			;404e   ; fin del cuadro
pone_registro_del_vdp:		; escribe un registro del VDP, y de paso borra su copia
	ld hl,00000h		;404f   ; HL a cero
	ld (040f8h),hl		;4052   ; 0x40F8 cae dentro de la propia ROM, o sea que esta escritura no llega a ninguna parte
	jp 00047h		;4055   ; BIOS WRTVDP - Writes data in the VDP-register | WRTVDP con lo que traiga BC

; ----------------------------------------------------------------------
; ===== Las dos sumas de 8 sobre 16 bits =====
; ----------------------------------------------------------------------
suma_a_hl:		; HL = HL + A, con el acarreo a mano
	add a,l			;4058   ; A mas el byte bajo
	ld l,a			;4059   ; que vuelve a HL
	ret nc			;405a   ; si no hubo acarreo ya esta
	inc h			;405b   ; y si lo hubo, sube el byte alto
	ret			;405c   ; y ya esta
suma_a_de:		; DE = DE + A, la misma cuenta sobre el otro par
	add a,e			;405d   ; la misma cuenta sobre E
	ld e,a			;405e   ; el byte bajo de DE
	ret nc			;405f   ; sin acarreo no hay mas
	inc d			;4060   ; y con el, sube D
	ret			;4061   ; hecho

; ----------------------------------------------------------------------
; ===== EL DESPACHADOR, con la tabla pegada detras =====
; ----------------------------------------------------------------------
despacha:		; salta a la entrada A de la tabla que venga pegada detras del `call`
	add a,a			;4062   ; el indice se dobla porque las entradas son palabras
	pop hl			;4063   ; el `pop` recupera la direccion de retorno, que ES la tabla
	call suma_a_hl		;4064   ; y se le suma el indice
	ld e,(hl)			;4067   ; saca la entrada
	inc hl			;4068   ; el byte alto de la entrada
	ld d,(hl)			;4069   ; que completa DE
	ex de,hl			;406a   ; y a HL, que es desde donde se salta
	jp (hl)			;406b   ; y salta ahi, sin volver: la tabla se ha comido el retorno

; ----------------------------------------------------------------------
; ===== INIT: lo unico que hace es enganchar la interrupcion =====
; ----------------------------------------------------------------------
init:		; la direccion que trae la cabecera del cartucho
	di			;406c   ; lo primero, cerrar la interrupcion
	im 1		;406d   ; modo 1, el unico que usa la BIOS del MSX
	ld a,0c3h		;406f   ; un 0xC3, o sea un `jp`, en el primer byte de H.KEYI
	ld (0fd9ah),a		;4071   ; en 0xFD9A, el primer byte del gancho
	ld hl,latido		;4074   ; y detras la direccion del latido
	ld (0fd9bh),hl		;4077   ; y la direccion en los dos siguientes
	ld sp,0e400h		;407a   ; la pila, al final de la RAM que usa el juego
	ld hl,0e000h		;407d   ; desde la primera variable
	ld de,0e001h		;4080   ; a la siguiente, que es el truco de propagar un byte con `ldir`
	ld bc,003ffh		;4083   ; 0x3FF bytes
	ld (hl),000h		;4086   ; borra los 0x400 bytes de variables de 0xE000 en adelante
	ldir		;4088   ; y se propaga el cero por todas
	ld a,001h		;408a   ; uno
	ld (0e005h),a		;408c   ; echa el cerrojo ANTES de tocar el VDP
	call monta_la_pantalla		;408f   ; prepara la pantalla: registros del VDP y VRAM a cero
	xor a			;4092   ; y a cero otra vez
	ld (0e005h),a		;4093   ; y lo suelta
	call 0013eh		;4096   ; BIOS RDVDP - Reads VDP status register | acepta la interrupcion que hubiera pendiente
	ei			;4099   ; abre la interrupcion, que es lo que pone el juego en marcha
L_409A:
	jr L_409A		;409a   ; a partir de aqui no hace nada mas: el juego entero corre en la interrupcion
L_409C:
	jp arranca_melodia		;409c   ; la melodia que le llegue en A

; ----------------------------------------------------------------------
; ===== La escena del cuadro =====
; ----------------------------------------------------------------------
corre_la_escena:		; mira el estado y despacha la escena que toque
	ld a,(0e002h)		;409f
	bit 6,a		;40a2   ; el bit 6 de (0xE002) distingue la partida de la presentacion
	ld a,(0e044h)		;40a4   ; (0xE044) es el nivel que se eligio en el menu
	jr nz,L_40AB		;40a7   ; en la partida vale el elegido
	ld a,003h		;40a9   ; y en la presentacion, el 3 fijo
L_40AB:
	ld (0e047h),a		;40ab   ; (0xE047) es el contador que la escena va a mirar
	ld hl,0e003h		;40ae   ; (0xE003), el reloj
	inc (hl)			;40b1   ; (0xE003) cuenta cuadros y no lo pone a cero nadie: es el reloj de fondo
	ld a,(0e000h)		;40b2   ; (0xE000) es la escena
	cp 007h		;40b5   ; la 7 es la unica que necesita continuacion
	jr z,L_40BD		;40b7
	cp 003h		;40b9   ; y de la 3 en adelante no se apila retorno
	jr nc,L_40C1		;40bb
L_40BD:
	ld hl,043a7h		;40bd   ; apila 0x43A7 como direccion de retorno de la escena
	push hl			;40c0   ; apilada queda
L_40C1:
	ld bc,(0e000h)		;40c1   ; C es la escena y B la subescena
	ld a,c			;40c5   ; el despachador va por la escena
	call despacha		;40c6   ; y despacha con la tabla que viene pegada aqui detras

; ----------------------------------------------------------------------
; DATOS tabla_de_escenas: 8 entradas, pegada detras del call del despachador;
;   la primera apunta a 0x40D9, justo detras de la tabla
;   0x40c9..0x40d9  (16 bytes)
DATA_tabla_de_escenas:
	defw 040d9h,04108h,0423ah,04265h,042fah,04344h,0434eh,04374h	; 40c9

; ======================================================================
; CODIGO 0x40d9..0x43ef  (790 bytes)
; ======================================================================



; ----------------------------------------------------------------------
; ===== LAS ESCENAS: una cadena de `djnz` por subescena. 0x40C1 carga BC de (0xE000): C es la escena y B la subescena. La tabla despacha por la escena, y ya dentro la subescena se elige BAJANDO por una cadena de `djnz`, cada uno de dos bytes: el trozo que corre es aquel en que B llega a cero =====
; ----------------------------------------------------------------------
L_40D9:
	djnz L_40EE		;40d9   ; subescena 0 si B ya venia a cero; si no, al siguiente escalon
	ld a,(0e003h)		;40db   ; (0xE003) es el reloj de cuadros
	rra			;40de   ; el bit 0 al acarreo
	ret nc			;40df   ; o sea que esto solo corre uno de cada dos cuadros
	call sube_el_rotulo		;40e0   ; dibuja una fila mas del logotipo de la casa
	ret nz			;40e3   ; mientras queden filas, no se pasa de subescena
	ld de,0487eh		;40e4   ; el marco del menu, comprimido
	call descomprime		;40e7   ; y ya con el logotipo entero, el marco
	xor a			;40ea   ; cero, que es la escena a la que se va
	jp espera_y_avanza		;40eb   ; y a la escena siguiente
L_40EE:
	djnz L_40FA		;40ee   ; subescena 1
	ld hl,0e004h		;40f0   ; (0xE004) es la cuenta atras de la subescena
	dec (hl)			;40f3   ; un cuadro menos de espera
	ret nz			;40f4   ; mientras no llegue a cero, no pasa nada
	ld a,001h		;40f5   ; la subescena 1
	jp L_4318		;40f7   ; y a montar la pantalla del titulo
L_40FA:
	call carga_los_registros		;40fa   ; subescena 2: monta la pantalla entera; registros del VDP y VRAM a cero
	call borra_la_pantalla		;40fd   ; borra la tabla de nombres
	call monta_la_fuente		;4100   ; los patrones
	call prepara_el_rotulo_del_titulo		;4103   ; y el resto
	jr L_415B		;4106   ; el mismo remate que la de abajo
L_4108:
	push bc			;4108   ; subescena 3, que ademas se usa de tejado para las de abajo
	ld a,b			;4109   ; B trae el escalon en que se entro
	and a			;410a   ; a cero, no hay rotulo que refrescar
	jr z,L_4113		;410b   ; y se salta el refresco
	call L_4547		;410d   ; los rotulos del tanteo
	call vuelca_los_sprites		;4110   ; el sonido
L_4113:
	pop bc			;4113   ; recupera el escalon
	djnz L_411F		;4114   ; subescena 3
	ld hl,0e004h		;4116   ; la cuenta atras
	dec (hl)			;4119   ; su cuenta atras
	jr z,L_415B		;411a   ; al llegar a cero, adelante
	jp bota_la_pelota_del_menu		;411c   ; y mientras, la pelota sigue botando
L_411F:
	djnz L_4145		;411f   ; subescena 4
	call bota_la_pelota_del_menu		;4121   ; la pelota del menu
	ld a,(0e003h)		;4124   ; uno de cada dos cuadros
	and 001h		;4127   ; el bit 0 del reloj
	ret nz			;4129   ; asi que esto solo corre uno de cada dos cuadros
	call saca_una_letra_mas		;412a   ; si aun no ha terminado, no sigue
	ret z			;412d   ; si el rotulo aun no ha salido entero, se espera
	ld a,00fh		;412e   ; melodia 0x0F
	call arranca_melodia		;4130   ; melodia 0x0F
	xor a			;4133   ; la secuencia vuelve a la primera
	ld (0e1b0h),a		;4134   ; (0xE1B0) es la secuencia y (0xE1B1) el paso dentro de ella
	ld a,002h		;4137   ; y el paso, al segundo
	ld (0e1b1h),a		;4139   ; (0xE1B1) es el paso dentro de la secuencia
	ld a,0eeh		;413c   ; 0xEE
	ld (0e074h),a		;413e   ; (0xE074) es la altura de la pelota de la demostracion
	ld a,030h		;4141   ; 0x30 cuadros de espera
	jr L_414E		;4143   ; y al remate comun
L_4145:
	djnz L_4151		;4145   ; subescena 5
	ld hl,0e004h		;4147   ; la cuenta atras
	dec (hl)			;414a   ; un cuadro menos
	ret nz			;414b   ; y hasta cero no se sigue
	ld a,040h		;414c   ; 0x40 marca la escena de destino
L_414E:
	jp espera_y_avanza		;414e   ; deja la espera y pasa de subescena
L_4151:
	djnz L_415D		;4151   ; subescena 6
	call L_4CE3		;4153   ; mueve a los munecos de la demostracion
	ld hl,0e004h		;4156   ; la cuenta atras
	dec (hl)			;4159   ; uno menos
	ret nz			;415a   ; y no se sigue hasta agotarla
L_415B:
	jr L_41D6		;415b   ; al remate de la escena
L_415D:
	djnz L_416F		;415d   ; subescena 7
	call L_4CE3		;415f   ; los munecos
	call L_4C2D		;4162   ; si el movimiento no ha acabado, se espera
	ret nz			;4165   ; y si el movimiento no ha acabado, se espera
	call L_417A		;4166   ; el rotulo pequeno de KONAMI, letra a letra
	ld hl,0e1b0h		;4169   ; y se pasa a la secuencia siguiente
	inc (hl)			;416c   ; a la secuencia siguiente
	jr L_41D6		;416d   ; y a rematar
L_416F:
	djnz L_41A1		;416f   ; subescena 8
	call L_4CE3		;4171   ; los munecos
	ld b,001h		;4174   ; B es la mascara del reloj: aqui, uno de cada dos cuadros
	call mueve_por_guion		;4176   ; el guion de movimiento
	ret nz			;4179   ; hasta que se acaba, no se sigue
L_417A:
	ld a,084h		;417a   ; melodia 0x84
	call arranca_melodia		;417c   ; melodia 0x84
	ld hl,0e1b1h		;417f   ; (0xE1B1), la cuenta de letras
	push hl			;4182   ; que hay que conservar
	ld c,(hl)			;4183   ; el paso actual
	call escribe_ocho_patrones		;4184   ; y con ella se escriben las letras que ya han salido
	pop hl			;4187   ; recupera el puntero
	ld a,(hl)			;4188   ; la cuenta
	inc a			;4189   ; y adelanta uno
	ld (hl),a			;418a   ; y la deja subida
	cp 009h		;418b   ; nueve pasos y se acaba
	ret nz			;418d   ; hasta las nueve no se sigue
	ld hl,0e1b0h		;418e   ; la secuencia
	inc (hl)			;4191   ; una mas
	jr L_41D6		;4192   ; y a rematar
L_4194:
	ld c,008h		;4194   ; entrada con la cuenta fija en ocho: el rotulo entero
escribe_ocho_patrones:		; vuelca los 8 bytes de 0x4B87 en la VRAM 0x3868
	ld b,000h		;4196   ; la cuenta va en C y B se pone a cero
	ld hl,03868h		;4198   ; destino en la tabla de nombres
	ld de,04b87h		;419b   ; el mapa del rotulo pequeno
	jp copia_a_vram		;419e   ; y se copia tal cual a la VRAM
L_41A1:
	djnz L_41D8		;41a1   ; subescena 9
	call L_4CE3		;41a3   ; los munecos de la demostracion
	ld a,(0e07ah)		;41a6   ; (0xE07A) y (0xE074) son la posicion de la pelota en la demostracion
	cp 018h		;41a9   ; si ya esta en 0x18, este golpe ya se dio
	jr z,L_41C7		;41ab   ; si ya vale 0x18, este golpe ya se dio
	ld a,(0e074h)		;41ad   ; la posicion de la pelota
	cp 015h		;41b0   ; solo se golpea con la pelota entre 0x15 y 0xA0
	jr c,L_41C7		;41b2   ; por debajo de 0x15 aun no llega
	cp 0a0h		;41b4   ; y el tope de arriba
	jr nc,L_41C7		;41b6   ; pasado, tampoco se golpea
	ld a,018h		;41b8   ; 0x18: la marca de golpe dado
	ld (0e07ah),a		;41ba   ; en (0xE07A), para no repetirlo
	ld a,006h		;41bd   ; seis
	ld (0e073h),a		;41bf   ; (0xE073), el efecto del golpe de la demostracion
	ld a,011h		;41c2   ; melodia 0x11
	call arranca_melodia		;41c4   ; melodia 0x11: el golpe
L_41C7:
	ld b,001h		;41c7   ; la mascara del reloj: uno de cada dos cuadros
	call mueve_por_guion		;41c9   ; espera a que el movimiento termine
	ret nz			;41cc   ; y hasta que el movimiento acabe, no se sigue
	ld a,003h		;41cd   ; melodia 3
	call arranca_melodia		;41cf   ; melodia 3
	ld hl,0e1b0h		;41d2   ; y a la secuencia siguiente
	inc (hl)			;41d5   ; a la secuencia siguiente
L_41D6:
	jr L_41EF		;41d6   ; y al remate
L_41D8:
	djnz L_41F1		;41d8   ; subescena 10
	call L_4CE3		;41da   ; los munecos
	ld b,000h		;41dd   ; mascara cero: se mueve todos los cuadros
	call mueve_por_guion		;41df   ; el guion de movimiento
	ret nz			;41e2   ; hasta acabarlo, nada
	ld a,005h		;41e3   ; melodia 5
	call arranca_melodia		;41e5   ; melodia 5
	call L_4CED		;41e8   ; recoloca a los munecos para el golpe siguiente
	ld hl,0e1b0h		;41eb   ; la secuencia
	inc (hl)			;41ee   ; una mas
L_41EF:
	jr avanza_subescena		;41ef   ; y a la subescena siguiente
L_41F1:
	djnz L_4203		;41f1   ; subescena 11
	ld b,001h		;41f3   ; uno de cada dos cuadros
	call mueve_por_guion		;41f5   ; el guion
	ret nz			;41f8   ; hasta acabarlo, nada
	ld a,006h		;41f9   ; melodia 6
	call arranca_melodia		;41fb   ; melodia 6
	call L_4D05		;41fe   ; la otra colocacion
	jr avanza_subescena		;4201   ; y adelante
L_4203:
	djnz L_4215		;4203   ; subescena 12: la espera larga antes de repetir
	ld a,(0e003h)		;4205   ; el reloj
	and 001h		;4208   ; uno de cada dos cuadros
	ret nz			;420a   ; uno de cada dos cuadros
	ld hl,0e075h		;420b   ; (0xE075) es la cuenta de la espera
	inc (hl)			;420e   ; la cuenta sube
	ld a,(hl)			;420f   ; y se mira
	cp 0fdh		;4210   ; y hasta 0xFD no se sale
	ret c			;4212   ; hasta 0xFD no se acaba: la espera mas larga de la demostracion
	jr avanza_subescena		;4213   ; y entonces, adelante
L_4215:
	djnz L_421D		;4215   ; subescena 13
	call borra_la_pantalla		;4217   ; borra la tabla de nombres
	jp avanza_escena		;421a   ; y a la escena siguiente
L_421D:
	call borra_la_pantalla		;421d   ; subescena 14: la partida de verdad empieza aqui
	ld a,034h		;4220   ; melodia 0x34
	call arranca_melodia		;4222   ; melodia 0x34
	call L_4AF8		;4225   ; la fuente, el fondo y su espejo
	call L_4B48		;4228   ; y encima el bloque de nombres del titulo
	call L_4CED		;422b   ; coloca a los munecos
	xor a			;422e   ; cero
	ld (0e045h),a		;422f   ; (0xE045) y (0xE046) son los dos tanteos, a cero
	ld (0e046h),a		;4232   ; (0xE046), el paso de la rampa de la pelota
	ld a,040h		;4235   ; 0x40 de espera, el doble de lo normal
	jp espera_y_avanza		;4237   ; 0x40 cuadros y adelante
L_423A:
	djnz L_4250		;423a   ; subescena 15
	call cuenta_el_montaje		;423c   ; mientras la pantalla se monta, se cuenta
	ld a,(0e052h)		;423f   ; (0xE052) mientras no llegue a cero, la pantalla sigue montandose
	or a			;4242   ; hasta que llegue a cero
	ret nz			;4243   ; no se sigue
L_4244:
	xor a			;4244   ; cero
L_4245:
	ld (0e000h),a		;4245   ; vuelve a la escena 0
	ld a,020h		;4248   ; 0x20 cuadros
	ld (0e004h),a		;424a   ; con 0x20 cuadros de espera
	jp L_431F		;424d   ; y a la escena siguiente, empezando por su primera subescena
L_4250:
	call borra_la_pantalla		;4250   ; borra la tabla de nombres
	ld hl,0e002h		;4253   ; (0xE002), el modo
	res 5,(hl)		;4256   ; apaga el bit 5 de (0xE002): se vuelve a un jugador
	call arranca_la_partida		;4258   ; y monta la pista entera
	ld a,020h		;425b   ; 0x20 cuadros, la espera de siempre

; ----------------------------------------------------------------------
; ===== Los dos remates que cierran casi todas las subescenas =====
; ----------------------------------------------------------------------
espera_y_avanza:		; deja A cuadros de espera en (0xE004) y cae en avanzar
	ld (0e004h),a		;425d   ; en (0xE004)
avanza_subescena:		; sube (0xE001), que es el escalon del `djnz`
	ld hl,0e001h		;4260   ; (0xE001) es el escalon de la cadena de `djnz`
	inc (hl)			;4263   ; uno mas
	ret			;4264   ; y al cuadro siguiente entrara por el escalon de al lado
L_4265:
	djnz L_427C		;4265   ; subescena 16
	ld hl,0e004h		;4267   ; la cuenta atras
	dec (hl)			;426a   ; un cuadro menos
	jr z,avanza_subescena		;426b   ; y al agotarse, adelante
	bit 3,(hl)		;426d   ; el bit 3 de la propia cuenta atras hace parpadear
	jp nz,L_4B62		;426f   ; con el bit puesto se repinta, y con el apagado se borra: eso es el parpadeo
	call L_455C		;4272   ; la fila del rotulo que toca
	ld bc,00010h		;4275   ; dieciseis tiles
	xor a			;4278   ; a cero, que es borrar
	jp 00056h		;4279   ; BIOS FILVRM - Fills VRAM with value | FILVRM: borra 16 bytes de la VRAM
L_427C:
	djnz L_4289		;427c   ; subescena 17
	call borra_la_pantalla		;427e   ; la tabla de nombres
	call carga_sprites_de_la_pelota		;4281   ; los sprites de la pelota
	call borra_el_estado		;4284   ; y el estado de juego, a cero
L_4287:
	jr avanza_subescena		;4287   ; y adelante
L_4289:
	djnz L_4293		;4289   ; subescena 18
	call borra_la_pantalla		;428b   ; la tabla de nombres
	call monta_la_pista		;428e   ; la pista entera
L_4291:
	jr L_4287		;4291   ; y al remate de arriba
L_4293:
	djnz L_42A6		;4293   ; subescena 19: vuelve a montar la pantalla del titulo
	call prepara_a_los_jugadores		;4295   ; coloca a los dos jugadores
	call L_7DED		;4298   ; la pantalla de nombres entera, comprimida
	call pinta_el_marcador		;429b   ; el marcador
	call vuelca_los_sprites		;429e   ; los sprites a la pantalla
	call L_45A8		;42a1   ; y el menu de nivel
	jr L_4291		;42a4   ; y a rematar

; ----------------------------------------------------------------------
; ===== EL MENU: elegir nivel y empezar =====
; ----------------------------------------------------------------------
L_42A6:
	djnz L_42EC		;42a6   ; subescena 20, la que atiende el menu
	call L_45B7		;42a8   ; mueve el cursor del nivel
	call lee_joystick_1		;42ab   ; el mando del jugador 1
	ld d,a			;42ae   ; el del joystick, guardado
	call lee_teclado_1		;42af   ; y el del 2, sumados: en el menu vale cualquiera de los dos
	or d			;42b2   ; y sumado al del teclado
	ld hl,0e040h		;42b3   ; (0xE040) guarda lo de antes
	call guarda_y_filtra		;42b6   ; (0xE040) guarda lo de antes, para quedarse solo con lo que se ACABA de pulsar
	or a			;42b9   ; si no hay nada nuevo
	ret z			;42ba   ; si no se ha pulsado nada nuevo, nada que hacer
	ld b,a			;42bb   ; el mando nuevo, a B
	and 030h		;42bc   ; los bits 4 y 5 son los botones
	jr nz,L_42E2		;42be   ; con boton, a empezar
	ld hl,0e044h		;42c0   ; (0xE044) es el nivel elegido
	bit 3,b		;42c3   ; el bit 3 es arriba
	jr z,L_42CA		;42c5   ; sin el bit 3, se prueba el otro
	inc (hl)			;42c7   ; arriba: un nivel mas
	jr L_42CF		;42c8   ; y a rematar
L_42CA:
	bit 2,b		;42ca   ; y el bit 2, abajo
	jr z,L_42D4		;42cc   ; y sin el bit 2 tampoco, no hay cambio
	dec (hl)			;42ce   ; abajo: un nivel menos
L_42CF:
	ld a,001h		;42cf   ; uno
	call arranca_melodia		;42d1   ; melodia 1: el chasquido del menu
L_42D4:
	ld a,(hl)			;42d4   ; el nivel que ha quedado
	cp 005h		;42d5   ; pasado el ultimo vuelve al primero
	jr nz,L_42DC		;42d7   ; si no es el 5, no da la vuelta
	ld (hl),000h		;42d9   ; y si lo es, al primero
	ret			;42db   ; hecho
L_42DC:
	cp 0ffh		;42dc   ; y por debajo del primero, al ultimo: cinco niveles, del 0 al 4
	ret nz			;42de   ; y si no es 0xFF, tampoco
	ld (hl),004h		;42df   ; por debajo del primero, al ultimo
	ret			;42e1   ; hecho
L_42E2:
	call L_45E8		;42e2   ; borra el cursor del nivel
	ld a,0a5h		;42e5   ; 0x5108 con A: el aviso corto, no una melodia entera
	call suena_si_hay_partida		;42e7   ; el aviso corto de arranque
	jr avanza_escena		;42ea   ; y a la escena siguiente
L_42EC:
	call L_4B4B		;42ec   ; pone el fondo negro y monta el bloque de nombres
	call L_4D44		;42ef   ; coloca a los munecos
	call vuelca_los_sprites		;42f2   ; los sprites a la pantalla
	ld a,060h		;42f5   ; 0x60 cuadros de espera, el triple de lo normal
	jp espera_y_avanza		;42f7   ; y 0x60 cuadros de espera
L_42FA:
	djnz L_430C		;42fa   ; subescena 21
	ld hl,0e004h		;42fc   ; la cuenta atras
	dec (hl)			;42ff   ; uno menos
	ret nz			;4300   ; hasta agotarla, nada
	call L_45E8		;4301   ; borra el cursor
	call L_4567		;4304   ; y escribe el ordinal del set: 1ST, 2ND o 3RD
	ld a,0a0h		;4307   ; 0xA0 cuadros: la espera mas larga de todas
	jp espera_y_avanza		;4309   ; 0xA0 cuadros para leerlo
L_430C:
	djnz L_4324		;430c   ; subescena 22
	ld hl,0e004h		;430e   ; la cuenta atras
	dec (hl)			;4311   ; uno menos
	ret nz			;4312   ; y hasta cero, nada
	call L_45E8		;4313   ; borra el cursor
L_4316:
	ld a,020h		;4316   ; 0x20 cuadros
L_4318:
	ld (0e004h),a		;4318   ; en (0xE004)

; ----------------------------------------------------------------------
; ===== Cambiar de escena =====
; ----------------------------------------------------------------------
avanza_escena:		; sube (0xE000) y pone la subescena a cero
	ld hl,0e000h		;431b   ; (0xE000), la escena
	inc (hl)			;431e   ; una mas
L_431F:
	xor a			;431f   ; la subescena vuelve al primer escalon del `djnz`
	ld (0e001h),a		;4320   ; y la subescena vuelve al primer escalon
	ret			;4323   ; hecho
L_4324:
	call prepara_a_los_jugadores		;4324   ; subescena 23
	call L_7DED		;4327   ; el bloque de nombres de la pista
	call pinta_el_marcador		;432a   ; y el marcador encima
	ld a,(0e002h)		;432d   ; el modo
	bit 5,a		;4330   ; el bit 5 de (0xE002): dos jugadores
	jr z,L_4341		;4332   ; con un jugador no hay cambio de campo
	ld a,(0e053h)		;4334   ; (0xE053) es el set que se juega
	and a			;4337   ; (0xE053), el set
	ld a,001h		;4338   ; uno
	jr z,L_4341		;433a   ; y en el primero tampoco
	call L_6E08		;433c   ; el rotulo CHANGE COURT
	ld a,050h		;433f   ; 0x50 cuadros para leerlo
L_4341:
	jp espera_y_avanza		;4341   ; 0x50 cuadros y adelante
L_4344:
	call corre_el_punto		;4344   ; un cuadro de juego
	ld a,(0e00dh)		;4347   ; (0xE00D) es el aviso de que la partida ha terminado
	and a			;434a
	jr nz,L_4316		;434b
	ret			;434d
L_434E:
	djnz L_435A		;434e   ; subescena 24
	ld hl,0e002h		;4350   ; (0xE002), el modo
	ld a,(hl)			;4353   ; tal como esta
	and 0bfh		;4354   ; apaga el bit 6 de (0xE002): se sale de la partida
	ld (hl),a			;4356   ; y devuelto sin el bit 6: se sale de la partida
	jp avanza_escena		;4357   ; y a la escena siguiente
L_435A:
	xor a			;435a   ; cero
	ld (0e00dh),a		;435b   ; (0xE00D), el aviso de partida terminada
	ld hl,0e050h		;435e   ; (0xE050) y (0xE051): los sets ganados por cada uno
	ld b,002h		;4361   ; los dos
L_4363:
	ld a,(hl)			;4363   ; los sets de este
	cp 002h		;4364   ; dos sets ganan la partida
	jp z,avanza_subescena		;4366   ; y entonces se pasa a la subescena del final
	inc hl			;4369   ; el otro jugador
	djnz L_4363		;436a   ; y se mira igual
	call L_45E8		;436c   ; borra el cursor
	ld a,004h		;436f   ; la escena 4
	jp L_4245		;4371   ; y se entra por ella
L_4374:
	djnz L_4381		;4374   ; subescena 1
	ld hl,0e004h		;4376   ; la cuenta atras
	dec (hl)			;4379   ; uno menos
	ret nz			;437a   ; hasta agotarla, nada
	call L_4679		;437b   ; el rotulo del ganador
	jp avanza_subescena		;437e   ; y adelante
L_4381:
	djnz L_438B		;4381   ; subescena 2
	ld a,(0e012h)		;4383   ; (0xE012) es el estado del primer canal de sonido
	or a			;4386   ; mientras siga sonando
	ret nz			;4387   ; no se pasa: la escena espera a la musica
	jp avanza_subescena		;4388   ; y cuando calla, adelante
L_438B:
	djnz L_439A		;438b   ; subescena 3
	call borra_la_pantalla		;438d   ; la tabla de nombres
	ld hl,0e050h		;4390   ; los sets ganados
	xor a			;4393   ; cero
	ld (hl),a			;4394   ; el del primero
	inc hl			;4395
	ld (hl),a			;4396   ; y el del segundo: la partida vuelve a empezar de cero
	jp L_4244		;4397   ; y a la presentacion
L_439A:
	ld a,0b1h		;439a   ; melodia 0xB1
	call arranca_melodia		;439c   ; la de fin de partida
	call L_4668		;439f   ; el rotulo GAME SET
	ld a,080h		;43a2   ; 0x80 cuadros, la espera mas larga del juego
	jp espera_y_avanza		;43a4

; ----------------------------------------------------------------------
; ===== La escena que se apilo como retorno =====
; ----------------------------------------------------------------------
elige_los_jugadores:		; en el titulo, uno o dos jugadores y a jugar
	call lee_joystick_1		;43a7   ; el joystick del jugador 1
	ld d,a			;43aa   ; guardado
	call lee_teclado_1		;43ab   ; y su teclado
	or d			;43ae   ; los dos suman
	ld hl,0e040h		;43af   ; (0xE040), lo de antes
	call guarda_y_filtra		;43b2   ; y de ahi, solo lo que se acaba de pulsar
	and 0f3h		;43b5   ; sin los dos botones
	ret z			;43b7   ; sin nada nuevo, no hay nada que hacer
	ld hl,0e000h		;43b8   ; (0xE000), la escena
	ld b,(hl)			;43bb   ; (0xE000): en que escena estamos
	djnz L_43D9		;43bc   ; y si no es la primera, se elige en vez de empezar
	ld b,a			;43be   ; el mando nuevo
	and 030h		;43bf   ; los bits 4 y 5, los botones
	jr z,L_43DF		;43c1   ; sin boton, se cambia de opcion
	ld hl,043efh		;43c3   ; la tabla de los dos modos
	ld a,(0e042h)		;43c6   ; (0xE042) es lo elegido: 0 uno, 1 dos
	call suma_a_hl		;43c9   ; el indice sobre la tabla de dos
	ld a,(hl)			;43cc   ; el modo que sale
	ld (0e002h),a		;43cd   ; y su bit 5 es el que mira todo el juego
	ld hl,0e000h		;43d0   ; la escena
	ld (hl),003h		;43d3   ; escena 3, subescena 0: empieza
	inc hl			;43d5   ; y la subescena
	ld (hl),000h		;43d6   ; a cero: empieza la partida
	ret			;43d8   ; hecho
L_43D9:
	ld (hl),001h		;43d9   ; escena 1
	inc hl			;43db   ; y su subescena
	ld (hl),000h		;43dc   ; a cero
	ret			;43de   ; hecho
L_43DF:
	push bc			;43df   ; el mando, que hace falta luego
	call L_454C		;43e0   ; borra lo que hubiera
	pop af			;43e3   ; y se recupera en A
	ld hl,0e042h		;43e4   ; (0xE042), la opcion elegida
	and 003h		;43e7   ; los bits 0 y 1 cambian de opcion
	ret z			;43e9   ; sin las flechas, no se cambia
	ld a,(hl)			;43ea   ; la opcion
	xor 001h		;43eb   ; y el XOR alterna entre uno y dos jugadores
	ld (hl),a			;43ed   ; y devuelta cambiada: de uno a dos jugadores y al reves
	ret			;43ee   ; hecho

; ----------------------------------------------------------------------
; DATOS modos_de_juego: 0x40 y 0x60. Los indexa 0x43C3 con (0xE042) y el que
;   salga va a (0xE002), que es donde el `bit 5` de 0x4514 y 0x4685 mira si se
;   juega contra la maquina o entre dos
;   0x43ef..0x43f1  (2 bytes)
DATA_modos_de_juego:
	defb 040h	; 43ef
	defb 060h	; 43f0

; ======================================================================
; CODIGO 0x43f1..0x440f  (30 bytes)
; ======================================================================


borra_el_estado:		; 0xAB bytes desde 0xE045 a cero
	ld hl,0e045h		;43f1   ; desde (0xE045)
	ld bc,000abh		;43f4   ; 0xAB bytes de estado
	ld d,h			;43f7   ; el destino, el mismo sitio
	ld e,l			;43f8   ; copiado a DE
	inc e			;43f9   ; pero un byte mas alla
	ld (hl),000h		;43fa   ; un cero en el primero
	ldir		;43fc   ; y el `ldir` lo propaga por todos: el truco de rellenar con la copia
	ret			;43fe   ; hecho
esconde_todos_los_sprites:		; los 32 sprites, fuera
	ld bc,00080h		;43ff   ; 0x80 bytes: los 32 sprites
	jr L_4407		;4402   ; y al remate comun
esconde_casi_todos:		; los 19 primeros
	ld bc,0004ch		;4404   ; 0x4C bytes: solo los diecinueve primeros
L_4407:
	ld hl,03b00h		;4407   ; la tabla de atributos de sprite
	ld a,0e0h		;440a   ; 0xE0 en la coordenada Y es la fila prohibida del VDP
	jp 00056h		;440c   ; BIOS FILVRM - Fills VRAM with value

; ----------------------------------------------------------------------
; DATOS patrones_de_los_sets: los indices 0x10, 0x11 y 0x12, o sea "0", "1" y
;   "2". Los indexa 0x4413 y el que salga lo escribe WRTVRM
;   0x440f..0x4412  (3 bytes)
DATA_patrones_de_los_sets:
	defb 010h,011h,012h	; 440f

; ======================================================================
; CODIGO 0x4412..0x451e  (268 bytes)
; ======================================================================


escribe_un_digito:		; saca de la tabla el patron de (DE) y lo escribe en HL
	ld a,(de)			;4412   ; el indice
	ld de,0440fh		;4413   ; la tabla de los tres patrones
	call suma_a_de		;4416   ; mas el indice
	ld a,(de)			;4419   ; y el patron que sale
	jp 0004dh		;441a   ; BIOS WRTVRM - Writes data in VRAM

; ----------------------------------------------------------------------
; ===== EL MARCADOR =====
; ----------------------------------------------------------------------
pinta_el_marcador:		; los nombres, los sets y los dos tanteos
	ld hl,04624h		;441d   ; los guiones del saque
	ld a,(0e002h)		;4420   ; el modo
	bit 5,a		;4423   ; uno o dos jugadores cambia la pareja
	jr z,L_442A		;4425   ; con un jugador, la pareja de arriba
	ld hl,04628h		;4427   ; y con dos, la de abajo
L_442A:
	ld a,(0e04bh)		;442a   ; y el cambio de campo, el lado
	and a			;442d   ; cero es que no hay cambio de campo
	ld a,000h		;442e   ; indice cero
	jr z,L_4433		;4430   ; y si no hay cambio, ese
	inc a			;4432   ; y con cambio, el uno: los nombres van al otro lado
L_4433:
	add a,a			;4433   ; doblado, que la tabla es de palabras
	call suma_a_hl		;4434   ; sumado a la base
	ld e,(hl)			;4437   ; la entrada
	inc hl			;4438   ; su byte alto
	ld d,(hl)			;4439   ; que completa el puntero
	call pinta_rotulo		;443a   ; y se pinta el guion
	ld hl,039bdh		;443d   ; el sitio del set del primero
	ld de,0e050h		;4440   ; (0xE050) es un set ganado
	call escribe_un_digito		;4443   ; y se escribe
	ld hl,039a4h		;4446   ; el del segundo
	ld de,0e051h		;4449   ; y (0xE051) el otro
	call escribe_un_digito		;444c   ; igual
L_444F:
	ld de,0e132h		;444f   ; el tanteo del jugador 1
	ld hl,039dch		;4452   ; el tanteo del primero
	call escribe_el_tanteo		;4455   ; dos digitos
	ld hl,039c3h		;4458   ; y el del segundo
	ld de,0e133h		;445b   ; y el del 2

; ----------------------------------------------------------------------
; ===== Dos digitos BCD, sin ceros a la izquierda =====
; ----------------------------------------------------------------------
escribe_el_tanteo:		; los dos digitos de un byte BCD, ocultando el cero de las decenas
	ld b,001h		;445e   ; dos digitos
	ld c,000h		;4460   ; C es la mascara: a cero borra el digito
L_4462:
	ld a,(de)			;4462   ; el byte de tanteo, en BCD
	rra			;4463   ; los cuatro desplazamientos bajan el nibble alto
	rra			;4464   ; cuatro desplazamientos
	rra			;4465   ; bajan
	rra			;4466   ; el nibble alto
	and 00fh		;4467   ; al bajo: eso son las decenas
	jr z,L_446D		;4469   ; con decenas a cero, la mascara sigue borrando
	ld c,0ffh		;446b   ; con decenas, la mascara deja pasar
L_446D:
	dec b			;446d   ; salvo en el ultimo digito, que siempre se ve
	jr nz,L_4472		;446e   ; y si no era el ultimo digito, se queda borrando
	ld c,0ffh		;4470   ; en el ultimo, la mascara siempre pasa: el cero de la derecha SI se ve
L_4472:
	inc b			;4472   ; se recupera la cuenta
	add a,010h		;4473   ; 0x10 es el patron del '0'
	and c			;4475   ; y la mascara lo convierte en el patron 0, que es el espacio
	call 0004dh		;4476   ; BIOS WRTVRM - Writes data in VRAM
	inc hl			;4479   ; el tile de al lado
	ld a,(de)			;447a   ; el mismo byte otra vez
	and 00fh		;447b   ; ahora las unidades
	jr z,L_4481		;447d   ; unidades a cero: sigue la mascara de antes
	ld c,0ffh		;447f   ; y si no, pasa
L_4481:
	add a,010h		;4481   ; el patron del '0' mas el digito
	and c			;4483   ; filtrado por la mascara
	call 0004dh		;4484   ; BIOS WRTVRM - Writes data in VRAM
	dec de			;4487   ; y el byte de abajo: se recorre al reves
	inc hl			;4488   ; el tile siguiente
	djnz L_4462		;4489
	ret			;448b
borra_el_marcador:		; cuatro rectangulos de cinco tiles, con el patron 6
	ld hl,03982h		;448c   ; la primera fila que se borra
	ld b,001h		;448f   ; una sola
	call L_44A7		;4491   ; y se borra
	ld hl,03999h		;4494   ; la segunda
	ld b,001h		;4497   ; tambien una
	call L_44A7		;4499   ; igual
	ld hl,039a1h		;449c   ; la tercera
	call L_44A5		;449f   ; esta con la cuenta que traiga
	ld hl,039bah		;44a2   ; y la cuarta
L_44A5:
	ld b,004h		;44a5   ; cuatro filas seguidas
L_44A7:
	push bc			;44a7   ; la cuenta, que FILVRM se la come
	ld a,006h		;44a8   ; el patron 6, que es el que hace de vacio
	ld bc,00005h		;44aa   ; cinco tiles de ancho
	call 00056h		;44ad   ; BIOS FILVRM - Fills VRAM with value | cinco tiles por fila
	ld a,020h		;44b0   ; 0x20: bajar una fila
	call suma_a_hl		;44b2   ; y 0x20 mas alla esta la fila siguiente
	pop bc			;44b5   ; se recupera la cuenta
	djnz L_44A7		;44b6   ; y a la fila siguiente
	ret			;44b8   ; hecho
L_44B9:
	call pinta_los_resultados		;44b9   ; los rotulos de la pantalla de sets
	ld de,0e054h		;44bc   ; los tanteos de set del primero
	ld hl,0398eh		;44bf   ; y donde van
	call escribe_los_sets		;44c2   ; se escriben
	ld de,0e057h		;44c5   ; los del segundo
	ld hl,039aeh		;44c8   ; en su columna
escribe_los_sets:		; el tanteo de cada set jugado, uno debajo de otro
	ld a,(0e053h)		;44cb   ; (0xE053) dice cuantos sets van
	ld b,a			;44ce   ; tantos como sets llevados
L_44CF:
	push de			;44cf   ; el puntero, que la rutina lo mueve
	push bc			;44d0   ; y la cuenta
	call escribe_el_tanteo		;44d1   ; dos digitos del set
	pop bc			;44d4   ; se recuperan
	pop de			;44d5   ; los dos
	inc de			;44d6   ; y cada uno esta un byte y un tile mas alla
	inc hl			;44d7   ; y a la fila de abajo
	djnz L_44CF		;44d8   ; tantas veces como sets
	ret			;44da   ; hecho
pinta_los_resultados:		; la pantalla de sets: los rotulos y las bolas de cada uno
	ld hl,03969h		;44db   ; tres filas
	ld de,00e00h		;44de   ; tres filas de 14 tiles
	ld b,003h		;44e1   ; tres
	call L_45D7		;44e3   ; y se borran
	ld de,0451eh		;44e6   ; el marco
	call pinta_rotulo		;44e9   ; el marco
	call pinta_los_nombres		;44ec   ; y los nombres de los dos
	ld de,0e05ah		;44ef   ; (0xE05A): los sets ganados
	ld hl,0398dh		;44f2   ; donde van las marcas del primero
	call marca_los_sets		;44f5   ; y se ponen
	ld hl,039adh		;44f8   ; las del segundo
marca_los_sets:		; una bola por set ganado, y nada por el que no
	ld b,003h		;44fb   ; tres sets como mucho
L_44FD:
	ld a,(de)			;44fd   ; si este set se gano
	and a			;44fe   ; cero es que no
	ld a,0eeh		;44ff   ; 0xEE es el patron de la bola
	jr nz,L_4504		;4501   ; y si se gano, la bola
	xor a			;4503   ; y si no se gano, se borra
L_4504:
	call 0004dh		;4504   ; BIOS WRTVRM - Writes data in VRAM
	inc de			;4507   ; el set siguiente
	inc hl			;4508   ; y su sitio, que esta
	inc hl			;4509   ; tres tiles de separacion entre marca y marca
	inc hl			;450a   ; tres tiles mas alla
	djnz L_44FD		;450b   ; los tres
	ret			;450d   ; hecho
pinta_los_nombres:		; YOU y MSX, o 1UP y 2UP segun el modo
	ld de,0452bh		;450e   ; los nombres de un jugador
	ld a,(0e002h)		;4511   ; el modo
	bit 5,a		;4514   ; el bit 5 de (0xE002) es lo que los separa
	jr z,L_451B		;4516   ; con un jugador, YOU contra MSX
	ld de,04539h		;4518   ; y con dos, 1UP contra 2UP
L_451B:
	jp pinta_rotulo		;451b   ; y se pinta

; ----------------------------------------------------------------------
; DATOS guion_marco_del_menu: los cuatro patrones 0xEA..0xED separados por
;   espacios, en 0x396C
;   0x451e..0x452b  (13 bytes)
DATA_guion_marco_del_menu:
	defb 06ch,039h,0eah,000h,000h,0ebh,000h,000h,0ech,000h,000h,0edh,0ffh	; 451e  l9...........

; ----------------------------------------------------------------------
; DATOS guion_you_msx: "YOU" en 0x3989 y "MSX" en 0x39A9: el reparto de un
;   jugador
;   0x452b..0x4539  (14 bytes)
DATA_guion_you_msx:
	defb 089h,039h,039h,02fh,035h,0eah,0feh,0a9h,039h,02dh,033h,038h,0eah,0ffh	; 452b  .99/5...9-38..

; ----------------------------------------------------------------------
; DATOS guion_1up_2up: "1UP" en 0x3989 y "2UP" en 0x39A9: el reparto de dos
;   jugadores. Lo elige el `bit 5` de (0xE002) en 0x4514
;   0x4539..0x4547  (14 bytes)
DATA_guion_1up_2up:
	defb 089h,039h,011h,035h,030h,0eah,0feh,0a9h,039h,012h,035h,030h,0eah,0ffh	; 4539  .9.50...9.50..

; ======================================================================
; CODIGO 0x4547..0x457d  (54 bytes)
; ======================================================================


L_4547:
	ld bc,03b3ch		;4547   ; con BC a 0x3B3C
	jr L_454F		;454a   ; y al remate comun
L_454C:
	ld bc,00000h		;454c   ; y aqui a cero
L_454F:
	call L_455C		;454f   ; la fila donde va el cursor
	ld a,b			;4552   ; el primero de los dos patrones del cursor
	call 0004dh		;4553   ; BIOS WRTVRM - Writes data in VRAM
	ld a,c			;4556   ; y el segundo
	inc hl			;4557   ; en el tile de al lado
	call 0004dh		;4558   ; BIOS WRTVRM - Writes data in VRAM
	ret			;455b   ; hecho
L_455C:
	ld a,(0e042h)		;455c   ; (0xE042): uno o dos jugadores
	ld hl,03a69h		;455f   ; la fila de la primera opcion
	and a			;4562   ; cero es un jugador
	ret z			;4563   ; y ahi se queda
	ld l,0a9h		;4564   ; y si no, la fila de abajo: solo cambia el byte bajo
	ret			;4566   ; hecho
L_4567:
	ld a,(0e053h)		;4567   ; (0xE053), el set que se va a jugar
	add a,a			;456a   ; doblado, que la tabla es de palabras
	ld hl,04590h		;456b   ; la tabla de los tres ordinales
	call suma_a_hl		;456e   ; mas el indice
	ld e,(hl)			;4571   ; la entrada
	inc hl			;4572   ; su byte alto
	ld d,(hl)			;4573   ; que completa el puntero
	call pinta_rotulo		;4574   ; y se pinta 1ST, 2ND o 3RD
	ld de,0457dh		;4577   ; y detras, GAME y LOVE ALL
	jp pinta_rotulo		;457a   ; que es el tanteo de salida

; ----------------------------------------------------------------------
; DATOS guion_game_love_all: "GAME" en 0x398F y "LOVE ALL" en 0x39CC, el
;   tanteo de salida
;   0x457d..0x4590  (19 bytes)
DATA_guion_game_love_all:
	defb 08fh,039h,000h,027h,021h,02dh,025h,0feh,0cch,039h,02ch,02fh,036h,025h,000h,021h	; 457d  .9.'!-%..9,/6%.!
	defb 02ch,02ch,0ffh	; 458d

; ----------------------------------------------------------------------
; DATOS tabla_de_ordinales: 3 entradas: 0x4596, 0x459C y 0x45A2. La indexa
;   0x456B con (0xE053)
;   0x4590..0x4596  (6 bytes)
DATA_tabla_de_ordinales:
	defw 04596h,0459ch,045a2h	; 4590  -> DATA_guiones_de_ordinales 0x459c 0x45a2

; ----------------------------------------------------------------------
; DATOS guiones_de_ordinales: "1ST", "2ND" y "3RD" en 0x398C, seis bytes cada
;   uno: el destino, los tres patrones y el 0xFF
;   0x4596..0x45a8  (18 bytes)
DATA_guiones_de_ordinales:
	defb 08ch,039h,011h,033h,034h,0ffh	; 4596
	defb 08ch,039h,012h,02eh,024h,0ffh	; 459c
	defb 08ch,039h,013h,032h,024h,0ffh	; 45a2

; ======================================================================
; CODIGO 0x45a8..0x45f7  (79 bytes)
; ======================================================================


L_45A8:
	ld de,00b00h		;45a8   ; cuatro filas de once tiles
	ld hl,0396bh		;45ab   ; desde aqui
	call L_45D5		;45ae   ; se borran
	ld de,045f7h		;45b1   ; el guion de LEVEL
	call pinta_rotulo		;45b4   ; y se pinta
L_45B7:
	ld hl,039cbh		;45b7   ; la fila del cursor
	push hl			;45ba   ; que hace falta luego
	ld bc,0000bh		;45bb   ; once tiles
	xor a			;45be   ; a cero: borra el cursor anterior
	call 00056h		;45bf   ; BIOS FILVRM - Fills VRAM with value
	pop hl			;45c2   ; se recupera la fila
	ld de,0461fh		;45c3   ; la tabla de las cinco columnas
	ld a,(0e047h)		;45c6   ; (0xE047), el nivel
	call suma_a_de		;45c9   ; mas el nivel
	ld a,(de)			;45cc   ; la columna que sale
	call suma_a_hl		;45cd   ; sumada a la fila
	ld a,088h		;45d0   ; 0x88: el patron del cursor
	jp 0004dh		;45d2   ; BIOS WRTVRM - Writes data in VRAM
L_45D5:
	ld b,004h		;45d5   ; cuatro filas
L_45D7:
	push bc			;45d7   ; la cuenta, que FILVRM se la come
	ld b,000h		;45d8   ; el byte alto de la cuenta, a cero
	ld c,d			;45da   ; D trae el ancho
	ld a,e			;45db   ; y E el patron de relleno
	call 00056h		;45dc   ; BIOS FILVRM - Fills VRAM with value
	pop bc			;45df   ; se recupera la cuenta
	ld a,020h		;45e0   ; 0x20: bajar una fila
	call suma_a_hl		;45e2   ; al sitio de la fila siguiente
	djnz L_45D7		;45e5   ; tantas filas como diga B
	ret			;45e7   ; hecho
L_45E8:
	ld de,00e0ch		;45e8   ; catorce tiles de ancho, con el patron 0x0C
	ld hl,03969h		;45eb   ; desde esta fila
	call L_45D5		;45ee   ; se borran
	ld de,0460bh		;45f1   ; el guion del cursor de nivel
	jp pinta_rotulo		;45f4   ; y se pinta

; ----------------------------------------------------------------------
; DATOS guion_level: "LEVEL" en 0x396E y "1 2 3 4 5" en 0x39AC
;   0x45f7..0x460b  (20 bytes)
DATA_guion_level:
	defb 06eh,039h,02ch,025h,036h,025h,02ch,0feh,0ach,039h,011h,000h,012h,000h,013h,000h	; 45f7  n9,%6%,..9......
	defb 014h,000h,015h,0ffh	; 4607

; ----------------------------------------------------------------------
; DATOS guion_cursor_de_nivel: el par de patrones 0x6A y 0xCA en las cuatro
;   filas 0x396F, 0x398F, 0x39AF y 0x39CF
;   0x460b..0x461f  (20 bytes)
DATA_guion_cursor_de_nivel:
	defb 06fh,039h,06ah,0cah,0feh,08fh,039h,06ah,0cah,0feh,0afh,039h,06ah,0cah,0feh,0cfh	; 460b  o9j...9j...9j...
	defb 039h,06ah,0cah,0ffh	; 461b

; ----------------------------------------------------------------------
; DATOS niveles_seleccionables: 1, 3, 5, 7 y 9: los cinco valores que ofrece
;   el menu de nivel
;   0x461f..0x4624  (5 bytes)
DATA_niveles_seleccionables:
	defb 001h,003h,005h,007h,009h	; 461f

; ----------------------------------------------------------------------
; DATOS tabla_de_guiones_del_saque: 4 entradas: 0x462C, 0x462C, 0x4638 y
;   0x4650
;   0x4624..0x462c  (8 bytes)
DATA_tabla_de_guiones_del_saque:
	defw 0462ch,0462ch,04638h,04650h	; 4624  -> DATA_guion_saque_you_msx DATA_guion_saque_you_msx DATA_guion_saque_1up DATA_guion_saque_2up

; ----------------------------------------------------------------------
; DATOS guion_saque_you_msx: "YOU" en 0x3A1B y "MSX" en 0x3962. Se entra
;   tambien por 0x462E, saltandose la cabecera
;   0x462c..0x4638  (12 bytes)
DATA_guion_saque_you_msx:
	defb 01bh,03ah,039h,02fh,035h,0feh,062h,039h,02dh,033h,038h,0ffh	; 462c  .:9/5.b9-38.

; ----------------------------------------------------------------------
; DATOS guion_saque_1up: "1UP" en 0x3A1B, "2UP" en 0x3962 y el patron 0x06
;   tres veces en 0x397B y 0x3A02, que borra el otro lado
;   0x4638..0x4650  (24 bytes)
DATA_guion_saque_1up:
	defb 01bh,03ah,011h,035h,030h,0feh,062h,039h,012h,035h,030h,0feh,07bh,039h,006h,006h	; 4638  .:.50.b9.50.{9..
	defb 006h,0feh,002h,03ah,006h,006h,006h,0ffh	; 4648  ...:....

; ----------------------------------------------------------------------
; DATOS guion_saque_2up: el mismo reparto con los sitios cambiados: "1UP" en
;   0x397B y "2UP" en 0x3A02
;   0x4650..0x4668  (24 bytes)
DATA_guion_saque_2up:
	defb 07bh,039h,011h,035h,030h,0feh,002h,03ah,012h,035h,030h,0feh,01bh,03ah,006h,006h	; 4650  {9.50..:.50..:..
	defb 006h,0feh,062h,039h,006h,006h,006h,0ffh	; 4660  ..b9....

; ======================================================================
; CODIGO 0x4668..0x466e  (6 bytes)
; ======================================================================


L_4668:
	ld de,0466eh		;4668   ; el guion de GAME SET
	jp pinta_rotulo		;466b   ; y se pinta

; ----------------------------------------------------------------------
; DATOS guion_game_set: "GAME SET" en 0x38CC
;   0x466e..0x4679  (11 bytes)
DATA_guion_game_set:
	defb 0cch,038h,027h,021h,02dh,025h,000h,033h,025h,034h,0ffh	; 466e  .8'!-%.3%4.

; ======================================================================
; CODIGO 0x4679..0x46a1  (40 bytes)
; ======================================================================


L_4679:
	ld de,046a1h		;4679   ; el guion de WIN
	call pinta_rotulo		;467c   ; pintado
	ld de,0462eh		;467f   ; y detras, el nombre del que gana
	ld a,(0e002h)		;4682   ; el modo
	bit 5,a		;4685   ; el bit 5, dos jugadores
	jr z,L_468C		;4687   ; con uno, YOU o MSX
	ld de,0463ah		;4689   ; y con dos, 1UP o 2UP
L_468C:
	ld a,(0e050h)		;468c   ; (0xE050): los sets del primero
	cp 002h		;468f   ; dos sets es la partida ganada
	jr z,L_4698		;4691   ; y entonces gana el primero
	ld a,006h		;4693   ; y si no, seis bytes mas alla
	call suma_a_de		;4695   ; o sea el nombre del OTRO
L_4698:
	ld bc,00003h		;4698   ; tres tiles, que es lo que mide el nombre
	ld hl,038cch		;469b   ; al lado del WIN
	jp copia_a_vram		;469e   ; y se copian

; ----------------------------------------------------------------------
; DATOS guion_win: "WIN" y el patron 0x5B en 0x38CC
;   0x46a1..0x46ac  (11 bytes)
DATA_guion_win:
	defb 0cch,038h,000h,000h,000h,000h,037h,029h,02eh,01bh,0ffh	; 46a1  .8....7)...

; ======================================================================
; CODIGO 0x46ac..0x47d6  (298 bytes)
; ======================================================================



; ----------------------------------------------------------------------
; ===== El cambio de campo del tercer set =====
; ----------------------------------------------------------------------
mira_cambio_de_campo:		; decide si toca cambiar de lado, y lo anota en (0xE04B)
	ld a,(0e002h)		;46ac   ; el modo
	bit 5,a		;46af   ; sin dos jugadores no hay cambio de campo
	jr z,L_46E6		;46b1   ; sin dos jugadores no hay cambio de campo
	ld a,(0e053h)		;46b3   ; (0xE053) es el set
	dec a			;46b6   ; en el primero, nada
	jr z,L_46E2		;46b7   ; en el segundo set, siempre
	dec a			;46b9   ; en el segundo, siempre
	jr nz,L_46E6		;46ba   ; y en el cuarto en adelante, nunca
	ld a,(0e14ah)		;46bc   ; en el tercero solo cuando se cumple la condicion
	and a			;46bf   ; cero es que aun no se ha cambiado
	jr nz,L_46E2		;46c0   ; y si ya se cambio, se avisa igual
	ld b,002h		;46c2   ; los dos tanteos
	ld hl,0e132h		;46c4   ; (0xE132) y (0xE133) son los dos tanteos del set
L_46C7:
	ld a,(hl)			;46c7   ; el de este
	cp 010h		;46c8   ; el tanteo va en BCD -0x6760 lo sube con `daa`-, asi que 0x10 son DIEZ puntos: la regla real del cambio de lado en el set decisivo
	jr nc,L_46D1		;46ca   ; al llegar a diez, se cambia
	inc hl			;46cc   ; y si no, el del otro
	djnz L_46C7		;46cd   ; los dos
	jr L_46E6		;46cf   ; y si ninguno llega, no hay cambio
L_46D1:
	ld a,(0e14eh)		;46d1   ; y una sola vez: (0xE14E) es el pestillo
	and a			;46d4   ; cero es que aun no se ha hecho
	jr nz,L_46E2		;46d5   ; y si ya, no se repite
	ld de,0e140h		;46d7   ; (0xE140), el lado de cada uno
	ld a,(de)			;46da   ; tal como esta
	cpl			;46db   ; invertir (0xE140) es lo que pone a cada jugador en el otro lado
	ld (de),a			;46dc   ; y devuelto del reves: eso es cambiar de campo
	ld a,001h		;46dd   ; uno
	ld (0e14eh),a		;46df   ; en (0xE14E): el pestillo, para no cambiar dos veces
L_46E2:
	ld a,001h		;46e2   ; uno: si hay cambio pendiente
	jr L_46E7		;46e4   ; y a guardarlo
L_46E6:
	xor a			;46e6   ; cero: no lo hay
L_46E7:
	ld (0e04bh),a		;46e7   ; (0xE04B) es lo que el latido mira dos veces por cuadro
	ret			;46ea   ; hecho

; ----------------------------------------------------------------------
; ===== Y con el campo se cambian los mandos =====
; ----------------------------------------------------------------------
intercambia_los_mandos:		; permuta los dos bytes de mando de un jugador con los del otro
	ld hl,0e009h		;46eb   ; el mando del jugador 1
	ld de,0e049h		;46ee   ; y el del 2
	ld b,002h		;46f1   ; dos bytes cada uno: el estado crudo y las pulsaciones nuevas
L_46F3:
	ld c,(hl)			;46f3   ; el byte de uno
	ld a,(de)			;46f4   ; el del otro
	ld (hl),a			;46f5   ; que va al primero
	ld a,c			;46f6   ; el intercambio, por el clasico rodeo con C
	ld (de),a			;46f7   ; y el guardado, al segundo
	dec hl			;46f8   ; el byte de abajo de uno
	dec de			;46f9   ; y el del otro
	djnz L_46F3		;46fa   ; al terminar, cada jugador maneja al muneco del otro lado
	ret			;46fc   ; hecho
borra_la_pantalla:		; deja la tabla de nombres a cero
	call esconde_todos_los_sprites		;46fd   ; primero, los sprites fuera
	ld hl,03800h		;4700   ; la tabla de nombres
	ld bc,00300h		;4703   ; 768 bytes: las 24 filas de 32
	xor a			;4706   ; a cero
	jp 00056h		;4707   ; BIOS FILVRM - Fills VRAM with value

; ----------------------------------------------------------------------
; ===== Los dos accesos crudos al puerto de la VRAM =====
; ----------------------------------------------------------------------
prepara_escritura:		; SETWRT y el puerto de escritura guardado en C'
	ex af,af'			;470a   ; A se guarda, que SETWRT lo usa
	call 00053h		;470b   ; BIOS SETWRT - Enables VDP to write
	exx			;470e   ; al juego alterno de registros
	ld a,(00006h)		;470f   ; la BIOS tiene el puerto de datos del VDP en 0x0006
	ld c,a			;4712   ; en C', para que el bucle solo tenga que hacer `out (c),a`
	exx			;4713   ; y se vuelve
	ex af,af'			;4714   ; con A como estaba
	ret			;4715   ; hecho
prepara_lectura:		; la gemela: SETRD y el puerto de lectura de 0x0007
	call 00050h		;4716   ; BIOS SETRD - Enables VDP to read
	exx			;4719
	ld a,(00007h)		;471a
	ld c,a			;471d
	exx			;471e
	ret			;471f
copia_a_vram:		; LDIRVM con los pares al derecho
	ex de,hl			;4720
	jp 0005ch		;4721   ; BIOS LDIRVM - Block transfers to VRAM from memory
rellena_tres_tercios:		; FILVRM el mismo valor en los tres tercios de la pantalla
	ld d,003h		;4724
L_4726:
	push bc			;4726
	push de			;4727
	call 00056h		;4728   ; BIOS FILVRM - Fills VRAM with value
	ld de,00800h		;472b   ; cada tercio esta 0x800 mas arriba
	add hl,de			;472e
	pop de			;472f
	pop bc			;4730
	dec d			;4731
	jr nz,L_4726		;4732
	ret			;4734
descomprime_dos_tercios:		; el mismo bloque en dos tercios
	ld b,002h		;4735
	jr L_473B		;4737
descomprime_tres_tercios:		; y aqui en los tres
	ld b,003h		;4739
L_473B:
	push bc			;473b
	push de			;473c   ; el `push de` es lo que hace que se repita el MISMO bloque: DE vuelve al principio
	call L_4781		;473d
	ld de,00800h		;4740
	add hl,de			;4743
	pop de			;4744
	pop bc			;4745
	djnz L_473B		;4746
	ret			;4748
copia_tres_tercios:		; como 0x473B pero copiando en crudo, no descomprimiendo
	exx			;4749   ; la cuenta va en B', para no pisar el B de quien llama
	ld b,003h		;474a
L_474C:
	exx			;474c   ; al juego alterno, donde va la cuenta
	push bc			;474d   ; la cuenta
	push de			;474e   ; y el origen
	call copia_a_vram		;474f   ; se copia el bloque
	ld de,00800h		;4752   ; un tercio
	add hl,de			;4755   ; mas al destino
	pop de			;4756   ; se recupera el origen
	pop bc			;4757   ; y la cuenta
	exx			;4758   ; al juego alterno otra vez
	djnz L_474C		;4759   ; los tres tercios
	ret			;475b   ; hecho
L_475C:
	ld c,0ffh		;475c   ; la mascara que deja pasar los bytes
	jr L_476C		;475e   ; y se entra sin leer cabecera
L_4760:
	ld c,000h		;4760
	jr L_4766		;4762

; ----------------------------------------------------------------------
; ===== EL INTERPRETE DE ROTULOS, con sus cuatro puertas =====
; ----------------------------------------------------------------------
pinta_rotulo:		; lee el destino del guion y escribe los patrones tal cual
	ld c,0ffh		;4764   ; la mascara: 0xFF deja pasar el byte
L_4766:
	ex de,hl			;4766
	ld e,(hl)			;4767   ; los dos primeros bytes del guion son el destino en la VRAM
	inc hl			;4768
	ld d,(hl)			;4769
	ex de,hl			;476a
	inc de			;476b   ; y DE queda en el primer patron
L_476C:
	ld a,(de)			;476c   ; el bucle: un byte del guion
	inc de			;476d
	ld b,a			;476e
	inc b			;476f   ; 0xFF, o sea B+1 = 0: fin del guion
	ret z			;4770
	inc b			;4771
	jr z,L_4766		;4772   ; 0xFE: otro destino, se vuelve a leer la cabecera
	and c			;4774   ; la mascara. Con C=0 esto escribe ceros, y el mismo guion BORRA el rotulo
	call 0004dh		;4775   ; BIOS WRTVRM - Writes data in VRAM | un patron, en la tabla de nombres
	inc hl			;4778
	jr L_476C		;4779

; ----------------------------------------------------------------------
; ===== EL DESCOMPRESOR =====
; ----------------------------------------------------------------------
descomprime:		; saca el destino del propio bloque y lo suelta en la VRAM
	ex de,hl			;477b   ; los dos primeros bytes son el destino
	ld e,(hl)			;477c
	inc hl			;477d
	ld d,(hl)			;477e
	ex de,hl			;477f
	inc de			;4780
L_4781:
	call prepara_escritura		;4781   ; aqui se entra con el destino ya en HL, sin cabecera; y deja el puerto del VDP en C'
L_4784:
	ld a,(de)			;4784   ; un mandato
	and a			;4785   ; cero es el fin del bloque
	ret z			;4786   ; el 0x00 cierra el bloque
	inc de			;4787   ; al mandato siguiente
	ld b,a			;4788   ; el mandato, guardado
	and 07fh		;4789   ; el bit 7 separa las dos clases de mandato
	cp b			;478b   ; comparado con el mismo sin el bit 7
	jr z,L_479C		;478c   ; sin bit 7, es repeticion
	and a			;478e   ; y a cero pelado es el 0x80
	jr z,descomprime		;478f   ; el 0x80 pelado: cambiar de destino a media faena
	ld b,a			;4791   ; y con bit 7, un literal de tantos bytes
L_4792:
	ld a,(de)			;4792   ; un byte del literal
	inc de			;4793   ; y al siguiente
	exx			;4794   ; al juego alterno, donde esta el puerto
	out (c),a		;4795   ; al puerto, sin pasar por la BIOS: un `out` por byte
	exx			;4797   ; y de vuelta
	djnz L_4792		;4798   ; tantos como diga el mandato
	jr L_4784		;479a   ; y a por el mandato siguiente
L_479C:
	ld a,(de)			;479c   ; la repeticion lee UN byte
	inc de			;479d   ; y al mandato siguiente
L_479E:
	exx			;479e   ; al juego alterno
	out (c),a		;479f   ; y lo suelta B veces
	exx			;47a1   ; y de vuelta
	djnz L_479E		;47a2   ; tantas veces como diga la cuenta
	jr L_4784		;47a4   ; y a por el mandato siguiente

; ----------------------------------------------------------------------
; ===== El espejo =====
; ----------------------------------------------------------------------
invierte_los_bits:		; devuelve A con sus ocho bits del reves
	push bc			;47a6   ; BC, que hace falta entero
	ld c,a			;47a7   ; el byte a dar la vuelta
	ld b,008h		;47a8   ; ocho bits
L_47AA:
	rr c		;47aa   ; saca por la derecha de C y mete por la izquierda de A: eso es dar la vuelta al byte
	rla			;47ac   ; y entra por la izquierda de A
	djnz L_47AA		;47ad   ; ocho veces, un bit por vuelta
	pop bc			;47af   ; se recupera BC
	ret			;47b0   ; hecho

; ----------------------------------------------------------------------
; ===== Preparar la pantalla desde cero =====
; ----------------------------------------------------------------------
monta_la_pantalla:		; calla el sonido, borra los 16 KB de VRAM y carga los registros
	ld a,0b8h		;47b1   ; 0xB8 en el mezclador: todos los canales callados
	call escribe_el_mezclador		;47b3   ; y se escribe
	ld a,034h		;47b6   ; melodia 0x34
	call L_409C		;47b8   ; la melodia de arranque
	ld de,00000h		;47bb   ; desde el principio de la VRAM
	ld bc,04000h		;47be   ; 0x4000 bytes: la VRAM ENTERA
	xor a			;47c1   ; con ceros
	call 00056h		;47c2   ; BIOS FILVRM - Fills VRAM with value
carga_los_registros:		; vuelca los ocho bytes de 0x47D6 en R0..R7
	ld hl,047d6h		;47c5   ; la tabla de los ocho registros
	ld d,008h		;47c8   ; ocho
	ld c,000h		;47ca   ; empezando por el registro 0
L_47CC:
	ld b,(hl)			;47cc   ; el valor de este registro
	call 00047h		;47cd   ; BIOS WRTVDP - Writes data in the VDP-register
	inc hl			;47d0   ; al byte siguiente de la tabla
	inc c			;47d1   ; el registro siguiente
	dec d			;47d2   ; un registro menos
	jr nz,L_47CC		;47d3   ; hasta los ocho
	ret			;47d5   ; hecho

; ----------------------------------------------------------------------
; DATOS registros_del_vdp: R0..R7 tal como los vuelca L_47C5; SCREEN 2 con
;   NOMBRES en 0x3800, COLOR en 0x0000 y PATRONES en 0x2000. Los OCHO bytes
;   son identicos a los de Road Fighter
;   0x47d6..0x47de  (8 bytes)
DATA_registros_del_vdp:
	defb 002h	; 47d6
	defb 0e2h	; 47d7
	defb 00eh	; 47d8
	defb 07fh	; 47d9
	defb 007h	; 47da
	defb 076h	; 47db
	defb 003h	; 47dc
	defb 0e4h	; 47dd

; ======================================================================
; CODIGO 0x47de..0x487e  (160 bytes)
; ======================================================================


pon_el_color_de_fondo:		; escribe el registro 7 con lo que traiga B
	ld c,007h		;47de   ; el registro 7, el del color de fondo
	jp pone_registro_del_vdp		;47e0   ; y se escribe con lo que traiga B

; ----------------------------------------------------------------------
; ===== EL CUADRO: leer los mandos =====
; ----------------------------------------------------------------------
lee_los_mandos:		; el mando de cada jugador, y de cada uno lo que se acaba de pulsar
	call lee_mando_2		;47e3   ; primero el del jugador 2, que puede ser la maquina
	call lee_joystick_1		;47e6   ; el joystick del 1
	ld d,a			;47e9   ; el del joystick, guardado
	call lee_teclado_1		;47ea   ; y su teclado, sumados: vale cualquiera de los dos
	or d			;47ed   ; y sumado al del teclado
	ld hl,0e002h		;47ee   ; (0xE002), el modo
	bit 6,(hl)		;47f1   ; el bit 6 de (0xE002) distingue partida de presentacion
	call z,L_709D		;47f3   ; fuera de la partida, la maquina juega sola
	ld hl,0e009h		;47f6   ; el sitio del mando del primero

; ----------------------------------------------------------------------
; ===== El filtro de las pulsaciones NUEVAS =====
; ----------------------------------------------------------------------
guarda_y_filtra:		; deja el estado crudo en (HL) y en (HL-1) solo lo que ACABA de pulsarse
	ld c,(hl)			;47f9   ; lo que habia antes
	ld (hl),a			;47fa   ; y guarda lo de ahora
	xor c			;47fb   ; el XOR deja lo que ha cambiado
	and (hl)			;47fc   ; y el AND, solo lo que ha cambiado A PULSADO: los flancos de subida
	dec hl			;47fd   ; el byte de abajo, que es donde van los flancos
	ld (hl),a			;47fe   ; el resultado va un byte por debajo del estado crudo
	ret			;47ff   ; hecho

; ----------------------------------------------------------------------
; ===== El joystick, por el PSG =====
; ----------------------------------------------------------------------
lee_joystick_1:		; 0x8F en el registro 15 elige el puerto 1
	ld e,08fh		;4800   ; 0x8F: el puerto 1 del PSG
L_4802:
	ld a,00fh		;4802   ; entrada alterna con el selector ya puesto en E: 0xCF es el puerto 2
	call 00093h		;4804   ; BIOS WRTPSG - Writes data to PSG-register | el registro 15 del PSG es el de control de los puertos
	ld a,00eh		;4807   ; el registro 14 devuelve lo leido
	di			;4809   ; con la interrupcion cerrada, que el PSG es de dos pasos
	call 00096h		;480a   ; BIOS RDPSG - Reads value from PSG-register | y el 14 devuelve lo que hay en el elegido
	ei			;480d   ; y se vuelve a abrir
	cpl			;480e   ; las lineas del mando estan a cero cuando se pulsan, asi que se invierte
	and 03fh		;480f   ; cuatro direcciones y dos botones
	ret			;4811   ; hecho

; ----------------------------------------------------------------------
; ===== El teclado del jugador 1, disfrazado de joystick =====
; ----------------------------------------------------------------------
lee_teclado_1:		; arma con las flechas y el espacio el MISMO mapa de bits que el joystick
	ld a,007h		;4812   ; la fila 7 de la matriz
	call 00141h		;4814   ; BIOS SNSMAT - Returns the value of the specified line from the keyboard matrix | la fila 7 de la matriz
	cpl			;4817   ; pulsado es cero, asi que se invierte
	rrca			;4818   ; de ahi sale el boton, al bit 5
	and 020h		;4819   ; el bit 5, que es el boton
	ld e,a			;481b   ; guardado
	ld a,008h		;481c   ; y ahora la fila 8, la de las flechas
	call 00141h		;481e   ; BIOS SNSMAT - Returns the value of the specified line from the keyboard matrix | la fila 8 son las cuatro flechas
	cpl			;4821   ; invertida tambien
	rrca			;4822   ; dos desplazamientos
	rrca			;4823   ; dejan la primera flecha en su sitio
	ld b,a			;4824   ; y lo demas se guarda para las siguientes
	and 004h		;4825   ; arriba
	or e			;4827   ; sumado a lo que habia
	ld c,a			;4828   ; y guardado
	ld a,b			;4829   ; lo que quedaba
	rrca			;482a   ; dos desplazamientos mas
	rrca			;482b   ; para el par siguiente
	ld b,a			;482c   ; y otra vez a la reserva
	and 018h		;482d   ; y las dos de los lados
	or c			;482f   ; sumado
	ld c,a			;4830   ; y guardado
	ld a,b			;4831   ; lo que queda
	rrca			;4832   ; un desplazamiento mas
	and 003h		;4833   ; y abajo: al colocarlas asi, el resto del juego no distingue mando de teclado
	or c			;4835   ; y todo junto
	ret			;4836   ; hecho: el teclado ha quedado con la MISMA forma que el joystick
lee_mando_2:		; el del segundo jugador, que segun (0xE002) es una persona o la maquina
	ld a,(0e002h)		;4837   ; el modo
	bit 5,a		;483a   ; el bit 5 dice si hay dos jugadores
	jr nz,L_4843		;483c   ; con dos jugadores, el mando de verdad
	call sin_mando		;483e   ; con uno solo, quien mueve es la maquina
	jr L_484D		;4841   ; y con uno, a guardar el que salga
L_4843:
	ld e,0cfh		;4843   ; 0xCF: el segundo puerto de joystick
	call L_4802		;4845   ; el joystick del puerto 2
	ld d,a			;4848   ; guardado
	call lee_teclado_2		;4849   ; y su teclado
	or d			;484c   ; los dos suman
L_484D:
	ld hl,0e049h		;484d   ; y el suyo se guarda en (0xE049)
	jr guarda_y_filtra		;4850

; ----------------------------------------------------------------------
; ===== El teclado del jugador 2 =====
; ----------------------------------------------------------------------
lee_teclado_2:		; las teclas del segundo jugador, de cuatro filas distintas
	ld a,006h		;4852
	call 00141h		;4854   ; BIOS SNSMAT - Returns the value of the specified line from the keyboard matrix | cada fila aporta un bit, y el `rl b` los va apilando
	ld b,a			;4857
	ld a,003h		;4858
	call 00141h		;485a   ; BIOS SNSMAT - Returns the value of the specified line from the keyboard matrix
	srl a		;485d
	srl a		;485f
	rl b		;4861
	ld a,002h		;4863
	call 00141h		;4865   ; BIOS SNSMAT - Returns the value of the specified line from the keyboard matrix
	rla			;4868
	rla			;4869
	rl b		;486a
	ld a,005h		;486c
	call 00141h		;486e   ; BIOS SNSMAT - Returns the value of the specified line from the keyboard matrix
	rla			;4871
	rl b		;4872
	rla			;4874
	rla			;4875
	rla			;4876
	rl b		;4877
	ld a,b			;4879
	cpl			;487a   ; otra vez, pulsado es cero
	and 01fh		;487b   ; cinco bits: cuatro direcciones y un boton
	ret			;487d

; ----------------------------------------------------------------------
; DATOS rle_marco_del_menu: 17 bytes -> 20 de NOMBRES en dos tramos, 0x394A y
;   0x396C. Lo carga 0x40E4
;   0x487e..0x488f  (17 bytes)
DATA_rle_marco_del_menu:
	defb 04ah,039h,00ch,05ah,080h,06ch,039h,088h,033h,02fh,026h,034h,037h,021h,032h,025h	; 487e  J9.Z.l9.3/&47!2%
	defb 000h	; 488e

; ----------------------------------------------------------------------
; DATOS guion_creditos: dos filas de siete y ocho patrones en 0x3A6C y 0x3AAC,
;   encabezadas por 0xC1 y 0xC2
;   0x488f..0x48a6  (23 bytes)
DATA_guion_creditos:
	defb 06ch,03ah,0c1h,000h,0e0h,0dch,0d1h,0e9h,0d5h,0e2h,0feh,0ach,03ah,0c2h,000h,0e0h	; 488f  l:..........:...
	defb 0dch,0d1h,0e9h,0d5h,0e2h,0e3h,0ffh	; 489f

; ======================================================================
; CODIGO 0x48a6..0x48d5  (47 bytes)
; ======================================================================



; ----------------------------------------------------------------------
; ===== La fuente =====
; ----------------------------------------------------------------------
monta_la_fuente:		; los quince patrones sueltos y luego los 45 de la fuente
	ld hl,00008h		;48a6
	ld a,001h		;48a9
	ld b,00fh		;48ab   ; quince tiles
L_48AD:
	push bc			;48ad
	push af			;48ae
	push hl			;48af
	ld bc,00008h		;48b0
	call rellena_tres_tercios		;48b3   ; rellena los ocho bytes de un tile con el mismo valor
	pop hl			;48b6
	ld a,008h		;48b7
	call suma_a_hl		;48b9   ; y pasa al tile siguiente, ocho bytes mas alla
	pop af			;48bc
	inc a			;48bd   ; el valor de relleno sube de uno en uno
	pop bc			;48be
	djnz L_48AD		;48bf
	ld de,048d5h		;48c1   ; la fuente comprimida
	ld hl,02080h		;48c4   ; a 0x2080, o sea al tile 0x10 de PATRONES, que es el codigo del '0'
	call descomprime_tres_tercios		;48c7   ; y en los TRES tercios de la pantalla
	ld a,0f0h		;48ca   ; 0xF0: tinta blanca sobre fondo transparente
	ld hl,00080h		;48cc   ; 0x0080 es el COLOR de esos mismos tiles, porque en este cartucho el color va abajo
	ld bc,00168h		;48cf   ; 360 bytes, los mismos que ocupan los 45 patrones
	jp rellena_tres_tercios		;48d2

; ----------------------------------------------------------------------
; DATOS rle_fuente: 312 bytes -> 360 de PATRONES (45 tiles). Lo cargan DOS:
;   0x48C1 con L_4739 en 0x2080 -los tres tercios-, o sea los 45 patrones
;   desde el tile 0x10, que es el codigo '0'; y 0x4B34 con L_4781 una sola vez
;   en 0x3600
;   0x48d5..0x4a0d  (312 bytes)
DATA_rle_fuente:
	defb 08bh,000h,038h,044h,0c6h,0c6h,0c6h,044h,038h,000h,030h,070h,004h,030h,0c9h,0fch	; 48d5  ..8D...D8.0p.0..
	defb 000h,07ch,0c6h,006h,01ch,078h,0e0h,0feh,000h,07ch,0c6h,006h,01ch,006h,0c6h,07ch	; 48e5  .|...x...|.....|
	defb 000h,01ch,03ch,06ch,0cch,0cch,0feh,00ch,000h,0feh,0c0h,0fch,0c6h,006h,0c6h,07ch	; 48f5  ..<l...........|
	defb 000h,07ch,0c6h,0c0h,0fch,0c6h,0c6h,07ch,000h,0feh,0c6h,00ch,018h,030h,030h,030h	; 4905  .|.....|.....000
	defb 000h,07ch,0c6h,0c6h,07ch,0c6h,0c6h,07ch,000h,07ch,0c6h,0c6h,07eh,006h,0c6h,07ch	; 4915  .|..|..|.|..~..|
	defb 03ch,042h,099h,0a1h,0a1h,099h,042h,03ch,081h,000h,005h,018h,082h,000h,018h,020h	; 4925  <B....B<....... 
	defb 000h,004h,000h,001h,07eh,004h,000h,0c1h,01ch,036h,063h,063h,07fh,063h,063h,000h	; 4935  ....~....6cc.cc.
	defb 07eh,063h,063h,07eh,063h,063h,07eh,000h,03eh,063h,060h,060h,060h,063h,03eh,000h	; 4945  ~cc~cc~.>c```c>.
	defb 07ch,066h,063h,063h,063h,066h,07ch,000h,07fh,060h,060h,07eh,060h,060h,07fh,000h	; 4955  |fcccf|..``~``..
	defb 07fh,060h,060h,07eh,060h,060h,060h,000h,03eh,063h,060h,067h,063h,063h,03fh,000h	; 4965  .``~```.>c`gcc?.
	defb 063h,063h,063h,07fh,063h,063h,063h,000h,03ch,005h,018h,083h,03ch,000h,01fh,004h	; 4975  ccc.ccc.<...<...
	defb 006h,08bh,066h,03ch,000h,063h,066h,06ch,078h,07ch,06eh,067h,000h,006h,060h,093h	; 4985  ..f<.cflx|ng..`.
	defb 07fh,000h,063h,077h,07fh,07fh,06bh,063h,063h,000h,063h,073h,07bh,07fh,06fh,067h	; 4995  ..cw..kcc.cs{.og
	defb 063h,000h,03eh,005h,063h,0a3h,03eh,000h,07eh,063h,063h,063h,07eh,060h,060h,000h	; 49a5  c.>.c.>.~ccc~``.
	defb 03eh,063h,063h,063h,06fh,066h,03dh,000h,07eh,063h,063h,062h,07ch,066h,063h,000h	; 49b5  >cccof=.~ccb|fc.
	defb 03eh,063h,060h,03eh,003h,063h,03eh,000h,07eh,006h,018h,001h,000h,006h,063h,082h	; 49c5  >c`>.c>.~.....c.
	defb 03eh,000h,004h,063h,0a6h,036h,01ch,008h,000h,063h,063h,06bh,06bh,07fh,077h,022h	; 49d5  >..c.6...cckk.w"
	defb 000h,063h,076h,03ch,01ch,01eh,037h,063h,000h,066h,066h,07eh,03ch,018h,018h,018h	; 49e5  .cv<..7c.ff~<...
	defb 000h,07fh,007h,00eh,01ch,038h,070h,07fh,000h,00fh,01fh,004h,0ffh,089h,00fh,000h	; 49f5  .....8p.........
	defb 000h,0feh,0e0h,0e0h,0c0h,0c0h,080h,000h	; 4a05  ........

; ======================================================================
; CODIGO 0x4a0d..0x4a61  (84 bytes)
; ======================================================================


prepara_el_rotulo_del_titulo:		; catorce pasos, empezando por la fila de abajo
	ld a,00eh		;4a0d   ; (0xE00A) son los pasos que le quedan
	ld (0e00ah),a		;4a0f   ; (0xE00A): catorce pasos
	ld hl,03aaah		;4a12   ; y (0xE00E) la fila por la que va, aqui la de mas abajo
	ld (0e00eh),hl		;4a15   ; (0xE00E): la fila por la que va
	jp L_4010		;4a18   ; y a cargar sus patrones
carga_los_patrones_del_titulo:		; el bloque comprimido y su color
	ld de,04a61h		;4a1b   ; el bloque comprimido del logotipo
	ld hl,06200h		;4a1e   ; a 0x2200, que con catorce bits es 0x6200
	call descomprime_tres_tercios		;4a21   ; en los tres tercios
	ld hl,00200h		;4a24   ; y su color
	ld bc,000d8h		;4a27   ; 0xD8 bytes, los mismos 27 tiles
	ld a,0f0h		;4a2a   ; 0xF0: blanco sobre transparente, 0xD8 bytes en los tres tercios
	jp rellena_tres_tercios		;4a2c   ; blanco sobre transparente

; ----------------------------------------------------------------------
; ===== El rotulo del titulo, subiendo =====
; ----------------------------------------------------------------------
sube_el_rotulo:		; dibuja una fila mas del rotulo, una por paso
	ld hl,(0e00eh)		;4a2f   ; la fila por la que iba
	ld de,0ffe0h		;4a32   ; 0xFFE0 es menos 0x20: una fila MAS ARRIBA que la anterior
	add hl,de			;4a35   ; menos 0x20, o sea una fila mas arriba
	ld (0e00eh),hl		;4a36   ; y se guarda
	ld a,040h		;4a39   ; los patrones arrancan en 0x40
	ld b,003h		;4a3b   ; tres tiles
	call escribe_tiles_seguidos		;4a3d   ; tres tiles
	ld bc,00b0ch		;4a40   ; luego once, empezando en 0x0C
	call escribe_tiles_seguidos		;4a43   ; y doce mas
	ld b,c			;4a46   ; la cuenta, que venia en C
	call escribe_tiles_seguidos		;4a47   ; y once mas
	xor a			;4a4a   ; a cero
	call 00056h		;4a4b   ; BIOS FILVRM - Fills VRAM with value | lo que queda de fila, a cero
	ld hl,0e00ah		;4a4e   ; (0xE00A), los pasos que quedan
	dec (hl)			;4a51   ; y un paso menos
	ret			;4a52   ; hecho
escribe_tiles_seguidos:		; B patrones consecutivos desde A, y devuelve la fila de abajo
	push hl			;4a53   ; la fila, que el bucle la mueve
L_4A54:
	call 0004dh		;4a54   ; BIOS WRTVRM - Writes data in VRAM
	inc hl			;4a57   ; al tile de al lado
	inc a			;4a58   ; el patron siguiente
	djnz L_4A54		;4a59   ; tantos como diga B
	pop de			;4a5b   ; y se recupera la fila de entrada
	ld hl,00020h		;4a5c   ; 0x20: la fila de debajo
	add hl,de			;4a5f   ; mas 0x20: la de abajo
	ret			;4a60   ; que es lo que se devuelve

; ----------------------------------------------------------------------
; DATOS rle_marcador: 151 bytes -> 216 de PATRONES (27 tiles) en 0x2200,
;   0x2A00 y 0x3200. Lo carga 0x4A1B con L_4739
;   0x4a61..0x4af8  (151 bytes)
DATA_rle_marcador:
	defb 00fh,000h,001h,001h,006h,000h,082h,0ffh,0feh,008h,00fh,084h,0c3h,0c7h,0cfh,0dfh	; 4a61  ................
	defb 003h,0ffh,089h,0feh,0fch,0f8h,0f0h,0e0h,0c0h,080h,007h,007h,005h,000h,083h,003h	; 4a71  ................
	defb 0cfh,0dfh,005h,000h,083h,0e1h,0f9h,07dh,005h,000h,083h,0efh,0ffh,0f7h,005h,000h	; 4a81  .......}........
	defb 083h,007h,08fh,09eh,005h,000h,083h,0f0h,0f8h,078h,005h,000h,083h,0f7h,0ffh,0fbh	; 4a91  .........x......
	defb 005h,000h,08bh,08fh,0dfh,0f7h,00ch,01eh,01eh,00ch,000h,01eh,09eh,09eh,008h,00fh	; 4aa1  ................
	defb 090h,0ffh,0ffh,0dfh,0cfh,0c7h,0c3h,0c1h,0c0h,007h,087h,0c7h,0efh,0ffh,0ffh,0ffh	; 4ab1  ................
	defb 0fch,004h,0deh,084h,09eh,09fh,00fh,003h,005h,03dh,083h,07dh,0f9h,0e1h,008h,0e3h	; 4ac1  .........=.}....
	defb 090h,0dch,0c0h,0c7h,0deh,0dch,0deh,0cfh,0c3h,03ch,07ch,0fch,03ch,03ch,07ch,0fch	; 4ad1  .........<|.<<|.
	defb 0deh,008h,0f1h,008h,0e3h,008h,0deh,088h,038h,044h,0bah,0aah,0b2h,0aah,044h,038h	; 4ae1  ........8D....D8
	defb 003h,000h,001h,0ffh,004h,000h,000h	; 4af1

; ======================================================================
; CODIGO 0x4af8..0x4b7a  (130 bytes)
; ======================================================================


L_4AF8:
	call monta_la_fuente		;4af8   ; los quince colores lisos y la fuente
	ld de,04ef8h		;4afb   ; los patrones del fondo, en dos tercios
	ld hl,06400h		;4afe   ; a 0x2400, que con catorce bits es 0x6400
	call descomprime_dos_tercios		;4b01   ; en dos tercios
	ld hl,00400h		;4b04   ; su color
	ld de,05021h		;4b07   ; su color
	call descomprime_dos_tercios		;4b0a   ; en dos tercios tambien
	ld hl,00600h		;4b0d   ; y el mismo bloque otra vez
	ld de,05021h		;4b10   ; desde 0x0600: dos bandas de color con el mismo dibujo
	call descomprime_dos_tercios		;4b13   ; y otra vez, desplazado: dos bandas
	ld hl,02c00h		;4b16   ; el origen del espejo
	ld de,02600h		;4b19   ; y su destino
	ld b,002h		;4b1c   ; dos tercios
L_4B1E:
	push bc			;4b1e   ; la cuenta
	push hl			;4b1f   ; el origen
	push de			;4b20   ; y el destino
	ld bc,00200h		;4b21   ; 0x200 bytes reflejados, la otra mitad del dibujo
	call copia_reflejando		;4b24   ; 0x200 bytes, dandoles la vuelta
	pop de			;4b27   ; se recupera el destino
	ld hl,00800h		;4b28   ; y se le suma
	add hl,de			;4b2b   ; un tercio
	ex de,hl			;4b2c   ; que vuelve a DE
	pop hl			;4b2d   ; el origen, SIN tocar
	pop bc			;4b2e   ; y la cuenta
	djnz L_4B1E		;4b2f   ; los dos tercios
	ld hl,03600h		;4b31   ; el destino, en la zona alta de PATRONES
	ld de,048d5h		;4b34   ; la fuente comprimida
	call L_4781		;4b37   ; aqui UNA sola vez, sin repetir por tercios
	ld a,070h		;4b3a   ; 0x70: rojo claro sobre transparente
	ld hl,01600h		;4b3c   ; 0x1600 es el COLOR de los patrones que acaba de dejar en 0x3600
	ld bc,00180h		;4b3f   ; 0x180 bytes
	call 00056h		;4b42   ; BIOS FILVRM - Fills VRAM with value
	jp L_4B68		;4b45   ; y a cargar los sprites
L_4B48:
	call borra_la_pantalla		;4b48   ; la tabla de nombres
L_4B4B:
	ld b,0e0h		;4b4b   ; 0xE0: tinta 14 sobre fondo NEGRO
	call pon_el_color_de_fondo		;4b4d   ; y se escribe en el registro 7
	ld de,0509ch		;4b50   ; el bloque de nombres del titulo
	call descomprime		;4b53   ; que trae la mesa y las dos opciones
	call L_4B6E		;4b56   ; los sprites de la pantalla de titulo
	call vuelca_los_sprites		;4b59   ; volcados a la VRAM
	ld bc,03b3ch		;4b5c   ; los dos patrones del cursor
	call L_454F		;4b5f   ; puesto en su fila
L_4B62:
	ld de,0488fh		;4b62   ; el guion de las dos opciones
	jp pinta_rotulo		;4b65   ; y se pinta
L_4B68:
	ld de,04d5eh		;4b68   ; el bloque de sprites de la mesa
	jp descomprime		;4b6b   ; y se descomprime
L_4B6E:
	ld hl,04b7ah		;4b6e   ; los atributos de la pantalla de titulo
	ld de,0e070h		;4b71   ; al buffer de sprites
	ld bc,0000dh		;4b74   ; trece bytes: tres sprites y el 0xD0 que corta
	ldir		;4b77   ; copiados
	ret			;4b79   ; hecho

; ----------------------------------------------------------------------
; DATOS datos_4b7a: 13 bytes que carga 0x4B6E
;   0x4b7a..0x4b87  (13 bytes)
DATA_datos_4b7a:
	defb 01fh,08ah,01ch,000h,0e0h,04ah,050h,00fh,0e0h,0f1h,000h,006h,0d0h	; 4b7a  .....JP......

; ----------------------------------------------------------------------
; DATOS datos_4b87: 8 bytes que carga 0x419B
;   0x4b87..0x4b8f  (8 bytes)
DATA_datos_4b87:
	defb 000h,02bh,02fh,02eh,021h,02dh,092h,033h	; 4b87  .+/.!-.3

; ======================================================================
; CODIGO 0x4b8f..0x4bc3  (52 bytes)
; ======================================================================


L_4B8F:
	ld a,016h		;4b8f   ; entrada con la cuenta al maximo: el rotulo entero de golpe
	jr L_4B98		;4b91   ; y al bucle

; ----------------------------------------------------------------------
; ===== El rotulo que va saliendo letra a letra =====
; ----------------------------------------------------------------------
saca_una_letra_mas:		; escribe una columna mas del rotulo, en sus dos filas
	ld hl,0e045h		;4b93   ; (0xE045): por que columna va
	ld a,(hl)			;4b96   ; (0xE045) es por que letra va
	inc (hl)			;4b97   ; y se adelanta una
L_4B98:
	ld b,a			;4b98   ; la columna, guardada
	inc a			;4b99   ; una mas
	ld c,a			;4b9a   ; que es cuantos bytes se copian
	ld a,016h		;4b9b   ; veintitres columnas: al pasarse, se acabo
	sub b			;4b9d   ; 0x16 menos la columna: se empieza por el FINAL del mapa
	jr c,L_4BC0		;4b9e   ; y pasada la ultima, se acabo
	ld de,04bc3h		;4ba0   ; la primera fila del mapa
	call suma_a_de		;4ba3   ; el trozo que toca
	ld b,000h		;4ba6   ; el byte alto de la cuenta, a cero
	ld hl,03880h		;4ba8   ; y su sitio en la pantalla
	push bc			;4bab   ; la cuenta
	push de			;4bac   ; y el origen
	call copia_a_vram		;4bad   ; se copia la primera fila
	pop de			;4bb0   ; se recupera el origen
	pop bc			;4bb1   ; y la cuenta
	ld a,017h		;4bb2   ; la segunda mitad esta 23 bytes mas alla, que es lo que mide la fila
	call suma_a_de		;4bb4   ; 0x17 mas alla, que es lo que mide una fila del mapa
	ld hl,038a0h		;4bb7   ; y va en la fila de abajo
	call copia_a_vram		;4bba   ; y se copia la segunda
	and 000h		;4bbd   ; cero: aun queda rotulo
	ret			;4bbf   ; hecho
L_4BC0:
	or 001h		;4bc0   ; devuelve uno cuando ya no queda letra que sacar
	ret			;4bc2   ; y aqui, con el rotulo ya entero

; ----------------------------------------------------------------------
; DATOS rotulo_de_dos_filas: el rotulo del menu, 23 columnas en dos filas de
;   23 bytes. 0x4BA0 saca una columna mas en cada pasada, y el `ld a,017h` de
;   0x4BB2 -que son 23- es lo que salta a la segunda fila. Cada mitad empieza
;   con nueve ceros: por eso el rotulo entra desde la izquierda
;   0x4bc3..0x4bf1  (46 bytes)
DATA_rotulo_de_dos_filas:
	defb 000h,000h,000h,000h,000h,000h,000h,000h,000h,080h,081h,082h,083h,084h,085h,0b4h,080h,08eh,08fh,083h,084h,085h,086h	; 4bc3  .......................
	defb 000h,000h,000h,000h,000h,000h,000h,000h,000h,087h,088h,089h,08ah,08bh,08ch,0b5h,087h,090h,091h,08ah,08bh,08ch,08dh	; 4bda  .......................

; ======================================================================
; CODIGO 0x4bf1..0x4c1b  (42 bytes)
; ======================================================================



; ----------------------------------------------------------------------
; ===== La pelota que bota en el menu =====
; ----------------------------------------------------------------------
bota_la_pelota_del_menu:		; la baja un pixel y le cambia la altura con la rampa
	ld a,01fh		;4bf1   ; 0x1F: el patron de la pelota del menu
	ld hl,0e078h		;4bf3   ; su sitio en el buffer de sprites
	ld (hl),a			;4bf6   ; el patron, fijo
	inc hl			;4bf7   ; la coordenada de abajo
	ld a,(hl)			;4bf8   ; tal como esta
	cp 08ah		;4bf9   ; al llegar a 0x8A se para
	jr z,L_4C16		;4bfb   ; al llegar a 0x8A, la pelota se para
	dec (hl)			;4bfd   ; y si no, un pixel mas
	inc hl			;4bfe   ; la otra coordenada
	ld a,(0e046h)		;4bff   ; (0xE046) es el paso de la rampa
	ld de,04c1bh		;4c02   ; la rampa de ida y vuelta
	call suma_a_de		;4c05   ; mas el paso
	ld a,(de)			;4c08   ; el valor que sale
	ld (hl),a			;4c09   ; y a la pelota
	ld hl,0e046h		;4c0a   ; (0xE046), el paso de la rampa
	ld a,(hl)			;4c0d   ; tal como esta
	inc a			;4c0e   ; uno mas
	cp 008h		;4c0f   ; ocho pasos y vuelta a empezar
	jr nz,L_4C14		;4c11   ; mientras no llegue a ocho, ese
	xor a			;4c13   ; y al llegar, vuelta a empezar
L_4C14:
	ld (hl),a			;4c14   ; guardado
	ret			;4c15   ; hecho
L_4C16:
	inc hl			;4c16   ; la altura de la pelota
	ld a,014h		;4c17   ; al pararse, se queda en 0x14
	ld (hl),a			;4c19   ; fijada en 0x14
	ret			;4c1a   ; hecho

; ----------------------------------------------------------------------
; DATOS rampa_de_ida_y_vuelta: 0, 4, 8, 12, 16, 12, 8, 4: sube y baja por los
;   mismos valores. La lee 0x4C02
;   0x4c1b..0x4c23  (8 bytes)
DATA_rampa_de_ida_y_vuelta:
	defb 000h	; 4c1b
	defb 004h	; 4c1c
	defb 008h	; 4c1d
	defb 00ch	; 4c1e
	defb 010h	; 4c1f
	defb 00ch	; 4c20
	defb 008h	; 4c21
	defb 004h	; 4c22

; ======================================================================
; CODIGO 0x4c23..0x4c56  (51 bytes)
; ======================================================================



; ----------------------------------------------------------------------
; ===== La demostracion: mover a un muneco por guion =====
; ----------------------------------------------------------------------
mueve_por_guion:		; saca de la secuencia el desplazamiento de este paso
	ld a,(0e003h)		;4c23   ; B es la mascara del reloj: cada cuantos cuadros se mueve
	and b			;4c26   ; el reloj filtrado por la mascara
	jr nz,L_4C2D		;4c27   ; si no sale cero, este cuadro no toca
	ld hl,0e075h		;4c29   ; y se cuenta como saltado
	inc (hl)			;4c2c   ; (0xE075) cuenta los cuadros saltados
L_4C2D:
	ld a,(0e1b0h)		;4c2d   ; (0xE1B0) es la secuencia
	add a,a			;4c30   ; doblada, que la tabla es de palabras
	ld hl,04c56h		;4c31   ; la tabla de las cinco secuencias
	call suma_a_hl		;4c34   ; mas el indice
	ld e,(hl)			;4c37   ; la entrada
	inc hl			;4c38   ; su byte alto
	ld d,(hl)			;4c39   ; que completa el puntero
	ld hl,0e1b2h		;4c3a   ; y (0xE1B2) el paso dentro de ella
	ld a,(hl)			;4c3d   ; el paso por el que va
	inc (hl)			;4c3e   ; que se adelanta solo
	call suma_a_de		;4c3f   ; sumado al guion
	ld a,(de)			;4c42   ; el desplazamiento de este paso
	cp 0a0h		;4c43   ; el 0xA0 cierra la secuencia
	jr z,L_4C4F		;4c45   ; el 0xA0 cierra la secuencia
	ld hl,0e074h		;4c47   ; (0xE074), la posicion del muneco
	add a,(hl)			;4c4a   ; el desplazamiento se suma a la posicion
	ld (hl),a			;4c4b   ; y se le suma el desplazamiento
	or 001h		;4c4c   ; y devuelve uno mientras quede secuencia
	ret			;4c4e   ; devuelve distinto de cero: aun queda guion
L_4C4F:
	xor a			;4c4f   ; cero
	ld (0e1b2h),a		;4c50   ; al acabarse, el paso vuelve a cero
	and 000h		;4c53   ; y devuelve cero: la secuencia se acabo
	ret			;4c55   ; hecho

; ----------------------------------------------------------------------
; DATOS tabla_de_secuencias: 5 entradas -0x4C60, 0x4C6E, 0x4C7E, 0x4CB6 y otra
;   vez 0x4CB6-, indexada por (0xE1B0) desde 0x4C31; (0xE1B2) es el paso
;   dentro de la secuencia y 0x4C3E lo adelanta
;   0x4c56..0x4c60  (10 bytes)
DATA_tabla_de_secuencias:
	defw 04c60h,04c6eh,04c7eh,04cb6h,04cb6h	; 4c56

; ----------------------------------------------------------------------
; DATOS secuencias_de_saque: las cinco secuencias, cada una cerrada por el
;   0xA0 que corta el recorrido; las dos ultimas entradas comparten la misma
;   0x4c60..0x4ce3  (131 bytes)
DATA_secuencias_de_saque:
	defb 001h,001h,001h,001h,002h,002h,002h,002h,002h,003h,003h,003h,003h,0a0h,0fdh,0fdh	; 4c60  ................
	defb 0feh,0feh,0feh,0ffh,0ffh,000h,001h,001h,002h,002h,002h,003h,003h,0a0h,0fch,0fch	; 4c70  ................
	defb 0fch,0fch,0fch,0fdh,0fdh,0fdh,0fdh,0fdh,0fdh,0feh,0feh,0feh,0ffh,0ffh,0ffh,000h	; 4c80  ................
	defb 000h,000h,001h,001h,001h,002h,002h,002h,002h,002h,003h,003h,003h,003h,003h,003h	; 4c90  ................
	defb 003h,003h,003h,003h,003h,004h,004h,004h,004h,004h,004h,004h,004h,004h,004h,004h	; 4ca0  ................
	defb 005h,005h,005h,005h,005h,0a0h,0fch,0fch,0fch,0fdh,0fdh,0fdh,0fdh,0fdh,0feh,0feh	; 4cb0  ................
	defb 0feh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,000h,000h,000h,000h,000h,000h,001h,001h,001h	; 4cc0  ................
	defb 001h,001h,001h,002h,002h,002h,003h,003h,003h,003h,003h,003h,003h,003h,003h,003h	; 4cd0  ................
	defb 004h,004h,0a0h	; 4ce0

; ======================================================================
; CODIGO 0x4ce3..0x4d0a  (39 bytes)
; ======================================================================


L_4CE3:
	ld hl,04d2ch		;4ce3   ; el tercer juego de posiciones
	ld a,(0e003h)		;4ce6   ; el reloj
	bit 3,a		;4ce9   ; el bit 3, que va cambiando cuatro veces por segundo
	jr nz,L_4CF0		;4ceb   ; con el bit puesto, ese
L_4CED:
	ld hl,04d0ah		;4ced   ; y con el apagado, el primero
L_4CF0:
	ld de,0e07ch		;4cf0   ; el buffer de sprites de los munecos
	ld bc,00015h		;4cf3   ; 21 bytes
	ldir		;4cf6   ; copiados
	ld hl,039d7h		;4cf8   ; el sitio de los tres patrones
	ld de,04d41h		;4cfb   ; y los patrones
	ld bc,00003h		;4cfe   ; tres
	call copia_a_vram		;4d01   ; copiados a la VRAM
	ret			;4d04   ; hecho
L_4D05:
	ld hl,04d1bh		;4d05   ; el segundo juego de posiciones
	jr L_4CF0		;4d08   ; y al mismo remate

; ----------------------------------------------------------------------
; DATOS estados_de_salida: tres arranques a 21 bytes que 0x4CF6 copia a
;   0xE07C, SOLAPADOS entre si: 0x4D0A y 0x4D1B los elige el `bit 3` de
;   (0xE003) en 0x4CE9, y 0x4D2C es el tercero. Van de 17 en 17, asi que cada
;   copia se lleva cuatro bytes del siguiente
;   0x4d0a..0x4d41  (55 bytes)
DATA_estados_de_salida:
	defb 065h,0bch,020h,004h,06ah,0bch,028h,00ah,067h,0c0h,024h,00fh,06ch,0b7h,02ch,006h	; 4d0a  e. .j.(.g.$.l.,.
	defb 0d0h,060h,0bch,040h,004h,069h,0bch,044h,00ah,06dh,0bfh,048h,00fh,071h,0c0h,04ch	; 4d1a  .`.@.i.D.m.H.q.L
	defb 00eh,0d0h,066h,0bdh,030h,004h,06bh,0bdh,034h,00ah,068h,0c6h,038h,006h,068h,0c1h	; 4d2a  ..f.0.k.4.h.8.h.
	defb 024h,00fh,055h,0bdh,03ch,00fh,0d0h	; 4d3a

; ----------------------------------------------------------------------
; DATOS tres_patrones: los 3 bytes que 0x4CFB manda a la VRAM 0x39D7 con
;   L_4720
;   0x4d41..0x4d44  (3 bytes)
DATA_tres_patrones:
	defb 0b2h	; 4d41
	defb 0b3h	; 4d42
	defb 0f2h	; 4d43

; ======================================================================
; CODIGO 0x4d44..0x4d55  (17 bytes)
; ======================================================================


L_4D44:
	call L_4B8F		;4d44   ; saca el rotulo del juego entero, de golpe
	ld hl,04d55h		;4d47   ; los sprites de la mesa
	ld de,0e070h		;4d4a   ; al buffer
	ld bc,00009h		;4d4d   ; nueve bytes: dos sprites y el 0xD0
	ldir		;4d50   ; copiados
	jp L_4194		;4d52   ; y el rotulo pequeno, entero tambien

; ----------------------------------------------------------------------
; DATOS estado_inicial: los 9 bytes que 0x4D50 copia a 0xE070
;   0x4d55..0x4d5e  (9 bytes)
DATA_estado_inicial:
	defb 01fh	; 4d55
	defb 08ah	; 4d56
	defb 018h	; 4d57
	defb 006h	; 4d58
	defb 01fh	; 4d59
	defb 08ah	; 4d5a
	defb 01ch	; 4d5b
	defb 006h	; 4d5c
	defb 0d0h	; 4d5d

; ----------------------------------------------------------------------
; DATOS rle_sprites_de_la_mesa: 410 bytes -> 672 de PATRONES DE SPRITE en
;   0x1800 (21 sprites de 16x16). Lo carga 0x4B68
;   0x4d5e..0x4ef8  (410 bytes)
DATA_rle_sprites_de_la_mesa:
	defb 000h,018h,086h,000h,007h,01fh,03fh,07fh,07fh,005h,0ffh,002h,07fh,089h,03fh,01fh	; 4d5e  ......?.......?.
	defb 007h,000h,0e0h,0f8h,0fch,0feh,0feh,005h,0ffh,002h,0feh,089h,0fch,0f8h,0e0h,000h	; 4d6e  ................
	defb 001h,007h,00fh,01fh,01fh,005h,03fh,002h,01fh,089h,00fh,007h,001h,000h,080h,0e0h	; 4d7e  ......?.........
	defb 0f0h,0f8h,0f8h,005h,0fch,002h,0f8h,088h,0f0h,0e0h,080h,000h,001h,003h,007h,007h	; 4d8e  ................
	defb 007h,00fh,002h,007h,087h,003h,001h,000h,080h,0c0h,0e0h,0e0h,007h,0f0h,002h,0e0h	; 4d9e  ................
	defb 087h,0c0h,080h,000h,001h,001h,003h,003h,007h,007h,002h,003h,002h,001h,003h,000h	; 4dae  ................
	defb 002h,080h,007h,0c0h,002h,080h,003h,000h,00fh,001h,081h,000h,00fh,080h,084h,000h	; 4dbe  ................
	defb 007h,01fh,01fh,005h,00fh,002h,01fh,002h,07fh,089h,03fh,01fh,007h,000h,0e0h,0f8h	; 4dce  ..........?.....
	defb 0fch,0feh,0feh,005h,0ffh,002h,0feh,08bh,0fch,0f8h,0e0h,000h,007h,01fh,01fh,00fh	; 4dde  ................
	defb 00eh,00ch,008h,009h,000h,087h,0e0h,0f8h,0fch,0feh,07eh,03fh,01fh,010h,000h,088h	; 4dee  ..........~?....
	defb 008h,018h,01ch,07eh,07fh,03fh,01fh,007h,008h,000h,002h,01fh,090h,03fh,07eh,0feh	; 4dfe  ...~.?.......?~.
	defb 0fch,0f8h,0e0h,007h,00fh,01ch,018h,018h,01ch,038h,078h,0fch,0b8h,003h,030h,08ch	; 4e0e  .........8x...0.
	defb 010h,000h,000h,0e0h,0f0h,098h,008h,008h,019h,00fh,00eh,008h,007h,000h,088h,036h	; 4e1e  ...............6
	defb 07fh,06bh,022h,000h,000h,001h,07fh,004h,0ffh,081h,07fh,00ah,000h,004h,080h,005h	; 4e2e  .k".............
	defb 000h,084h,001h,007h,007h,003h,005h,000h,082h,038h,07ch,005h,000h,084h,0c0h,0f0h	; 4e3e  .........8|.....
	defb 0b0h,0e0h,003h,000h,084h,004h,00eh,01eh,01ch,005h,000h,084h,070h,0f8h,0f8h,070h	; 4e4e  ............p..p
	defb 01ch,000h,09bh,007h,00fh,01ch,018h,018h,01dh,01fh,01eh,03ch,03ch,038h,0f8h,070h	; 4e5e  ...........<<8.p
	defb 010h,000h,000h,0e0h,0f0h,080h,000h,008h,018h,008h,00ch,00eh,003h,001h,007h,000h	; 4e6e  ................
	defb 082h,001h,003h,004h,000h,083h,060h,078h,0f0h,006h,000h,083h,0f0h,0b0h,0e0h,005h	; 4e7e  ......`x........
	defb 000h,082h,00ch,03eh,005h,000h,084h,030h,070h,0e0h,0c0h,028h,000h,084h,008h,004h	; 4e8e  ...>...0p..(....
	defb 040h,020h,00bh,000h,085h,080h,088h,010h,001h,002h,00ah,000h,086h,004h,008h,00ch	; 4e9e  @ ..............
	defb 018h,070h,0c0h,00ah,000h,08ah,020h,010h,030h,018h,00eh,003h,001h,003h,007h,003h	; 4eae  .p.... .0.......
	defb 003h,000h,086h,060h,0f0h,0f8h,0f8h,078h,030h,003h,000h,084h,080h,0c0h,0e0h,0c0h	; 4ebe  ...`...x0.......
	defb 003h,000h,086h,006h,00fh,01fh,01fh,01eh,00ch,003h,000h,086h,03fh,07fh,0ffh,0ffh	; 4ece  ............?...
	defb 03fh,01eh,00bh,000h,083h,080h,0c0h,0c0h,00ch,000h,082h,081h,042h,003h,07eh,026h	; 4ede  ?...........B.~&
	defb 000h,081h,070h,003h,0f8h,081h,070h,010h,000h,000h	; 4eee  ..p...p...

; ----------------------------------------------------------------------
; DATOS rle_patrones_del_fondo: 297 bytes -> 432 de PATRONES (54 tiles) en
;   0x2400 y 0x2C00. Lo carga 0x4AFB con L_4735
;   0x4ef8..0x5021  (297 bytes)
DATA_rle_patrones_del_fondo:
	defb 082h,000h,03fh,003h,07fh,003h,07ch,085h,000h,0e0h,0f9h,0f9h,0fdh,003h,07dh,082h	; 4ef8  ..?...|.......}.
	defb 000h,0e3h,006h,0f7h,092h,000h,081h,0c3h,0e3h,0f3h,0fbh,0ffh,0ffh,000h,0c0h,0e1h	; 4f08  ................
	defb 0e3h,0e7h,0e7h,0efh,0efh,000h,07fh,003h,0ffh,086h,0e1h,0c0h,080h,000h,000h,0c0h	; 4f18  ................
	defb 003h,0e0h,002h,000h,004h,07fh,003h,07ch,085h,038h,0fdh,0f9h,0f9h,0e1h,003h,001h	; 4f28  .......|.8......
	defb 081h,000h,007h,0f7h,081h,0e3h,003h,0ffh,085h,0dfh,0cfh,0c7h,0c3h,081h,003h,0efh	; 4f38  ................
	defb 002h,0e7h,087h,0e3h,0e1h,0c0h,087h,08fh,0c7h,0e1h,003h,0ffh,082h,07fh,0c0h,005h	; 4f48  ................
	defb 0e0h,087h,0c0h,080h,000h,0e0h,0f8h,0f8h,0fch,003h,07ch,082h,000h,003h,006h,007h	; 4f58  ..........|.....
	defb 084h,0fch,0f8h,0f8h,0e0h,004h,000h,007h,007h,083h,003h,001h,03dh,005h,018h,081h	; 4f68  ............=...
	defb 03ch,004h,000h,004h,080h,002h,000h,081h,0ffh,005h,0c0h,002h,000h,081h,0ffh,007h	; 4f78  <...............
	defb 000h,006h,0feh,002h,080h,081h,0ffh,005h,080h,005h,001h,003h,003h,081h,0ffh,004h	; 4f88  ................
	defb 080h,003h,000h,081h,0ffh,007h,000h,008h,0feh,081h,0ffh,007h,080h,005h,003h,00bh	; 4f98  ................
	defb 000h,008h,0feh,003h,080h,002h,0ffh,003h,080h,008h,0f8h,098h,005h,00bh,017h,02fh	; 4fa8  .............../
	defb 05eh,0bch,078h,0f0h,0fdh,0deh,08fh,007h,003h,001h,000h,000h,007h,087h,047h,0a7h	; 4fb8  ^.x...........G.
	defb 0d7h,0efh,0f7h,07fh,006h,040h,002h,0c0h,081h,000h,007h,001h,008h,007h,083h,0e0h	; 4fc8  .....@..........
	defb 0c0h,080h,004h,0ffh,081h,0e0h,008h,000h,083h,03fh,01fh,00fh,004h,0ffh,081h,007h	; 4fd8  .........?......
	defb 004h,03fh,004h,07fh,006h,003h,009h,007h,082h,000h,01fh,004h,03fh,002h,000h,006h	; 4fe8  .?..........?...
	defb 0ffh,002h,000h,081h,0ffh,008h,007h,005h,07fh,002h,000h,089h,0ffh,000h,000h,00fh	; 4ff8  ................
	defb 03fh,07fh,07fh,030h,00fh,007h,000h,084h,0ffh,000h,000h,0c0h,003h,0e0h,084h,006h	; 5008  ?..0............
	defb 00fh,0cfh,0e6h,004h,0e0h,082h,0c0h,080h,000h	; 5018  .........

; ----------------------------------------------------------------------
; DATOS rle_color_del_fondo: 123 bytes -> 432 de COLOR, cargado DOS veces: en
;   0x0400/0x0C00 por 0x4B07 y en 0x0600/0x0E00 por 0x4B10
;   0x5021..0x509c  (123 bytes)
DATA_rle_color_del_fondo:
	defb 07fh,0f0h,023h,0f0h,006h,0fch,002h,000h,006h,0fch,003h,0f0h,005h,0c0h,003h,0f0h	; 5021  ..#.............
	defb 005h,0fch,008h,0f0h,010h,0fch,081h,0f0h,007h,0c0h,008h,0fch,003h,0f0h,005h,0e0h	; 5031  ................
	defb 085h,0cch,0ffh,0ffh,0eeh,0eeh,003h,066h,085h,0cch,0ffh,0ffh,0eeh,0eeh,003h,066h	; 5041  .......f.......f
	defb 081h,0fch,004h,0efh,002h,0e6h,005h,006h,004h,046h,004h,060h,084h,064h,060h,064h	; 5051  .........F.`.d`d
	defb 064h,004h,060h,084h,064h,060h,064h,064h,004h,060h,084h,064h,060h,064h,064h,004h	; 5061  d.`.d`dd.`.d`dd.
	defb 060h,084h,064h,060h,004h,004h,008h,040h,009h,064h,006h,069h,084h,004h,044h,099h	; 5071  `.d`...@.d.i..D.
	defb 099h,004h,066h,082h,044h,064h,006h,069h,081h,064h,010h,040h,008h,064h,010h,040h	; 5081  ..f.Dd.i.d.@.d.@
	defb 005h,064h,002h,060h,081h,044h,018h,040h,010h,0f0h,000h	; 5091  .d.`.D.@...

; ----------------------------------------------------------------------
; DATOS rle_nombres_del_menu: 108 bytes -> 288 de NOMBRES en 0x38E0, nueve
;   filas de 32. Lo carga 0x4B50
;   0x509c..0x5108  (108 bytes)
DATA_rle_nombres_del_menu:
	defb 0e0h,038h,00ah,000h,08ch,01ah,02bh,02fh,02eh,021h,02dh,029h,000h,011h,019h,018h	; 509c  .8....+/.!-)....
	defb 015h,03ah,000h,081h,093h,01ah,000h,081h,094h,003h,095h,082h,096h,097h,003h,095h	; 50ac  .:..............
	defb 081h,0d4h,015h,000h,082h,098h,099h,003h,09ah,082h,09bh,09ch,003h,09ah,082h,0d9h	; 50bc  ................
	defb 0d8h,014h,000h,081h,09dh,004h,09eh,082h,09fh,0a0h,004h,09eh,081h,0ddh,015h,000h	; 50cc  ................
	defb 08ah,0a1h,0a2h,0a3h,0a4h,0a5h,0e5h,0e4h,0e3h,0e2h,0e1h,015h,000h,08ch,0a6h,0a7h	; 50dc  ................
	defb 0a8h,0a9h,0aah,0abh,0ebh,0eah,0e9h,0e8h,0e7h,0e6h,014h,000h,08ch,0ach,0adh,0aeh	; 50ec  ................
	defb 0afh,0b0h,0b1h,0f1h,0f0h,0efh,0eeh,0edh,0ech,00ah,000h,000h	; 50fc  ............

; ======================================================================
; CODIGO 0x5108..0x532d  (549 bytes)
; ======================================================================



; ----------------------------------------------------------------------
; ===== EL SONIDO: arrancar una melodia =====
; ----------------------------------------------------------------------
suena_si_hay_partida:		; como arranca_melodia, pero calla fuera de la partida
	di			;5108   ; cerrar la interrupcion, que esto lo llaman los dos lados
	push hl			;5109   ; y salvar lo que se toca
	ld hl,0e002h		;510a   ; (0xE002), el modo
	bit 6,(hl)		;510d   ; el bit 6 de (0xE002): solo dentro de la partida
	jr z,L_511E		;510f   ; fuera de la partida no suena
	jr L_5115		;5111   ; y dentro, adelante
arranca_melodia:		; pone en marcha la melodia A, respetando la que ya suene
	di			;5113   ; con la interrupcion cerrada, que esto lo llama tanto el latido como el juego
	push hl			;5114   ; se salva HL
L_5115:
	push de			;5115   ; DE
	push bc			;5116   ; BC
	push af			;5117   ; y AF
	call reparte_melodia		;5118   ; se reparte la melodia
	pop af			;511b   ; y se devuelven todos
	pop bc			;511c   ; BC
	pop de			;511d   ; DE
L_511E:
	pop hl			;511e   ; y HL
	ei			;511f   ; abre la interrupcion
	ret			;5120   ; hecho
reparte_melodia:		; elige a que canales va la melodia y si puede pisar a la que suena
	ld c,a			;5121   ; el numero de melodia
	ld b,002h		;5122   ; dos canales por omision
	ld hl,0e012h		;5124   ; el primer canal de melodia
	and 03fh		;5127   ; los 6 bits bajos son el numero; los altos, banderas
	cp 009h		;5129   ; por debajo de 9 es un efecto corto
	jr c,L_5134		;512b   ; por debajo de 9, un efecto corto
	cp 019h		;512d   ; de 9 a 0x18, dos canales
	jr c,L_5138		;512f   ; de 9 a 0x18, dos canales
	inc b			;5131   ; y de 0x19 en adelante, tres
	jr L_5138		;5132   ; y de ahi arriba, tres
L_5134:
	ld hl,0e030h		;5134   ; los efectos cortos van a su propio bloque de canal
	dec b			;5137   ; un canal en vez de dos
L_5138:
	ld a,(hl)			;5138   ; lo que ya esta sonando
	and 03fh		;5139   ; los seis bits bajos, que es el numero
	cp 025h		;513b   ; por encima de 0x25 es que no suena nada
	jr nc,L_5146		;513d   ; 0x25 o mas es que no suena nada
	ld a,c			;513f   ; la que se quiere poner
	and 03fh		;5140   ; su numero
	cp 025h		;5142   ; y si la nueva tampoco es una melodia de verdad, entra sin mas
	jr c,L_514F		;5144   ; si tampoco es melodia de verdad, entra sin pelear
L_5146:
	ld a,(hl)			;5146   ; la que suena
	and 03fh		;5147   ; su numero, que es su prioridad
	ld e,a			;5149   ; la prioridad de la que suena
	ld a,c			;514a   ; la nueva
	and 03fh		;514b   ; su numero
	cp e			;514d   ; y si la nueva es MENOR, no la pisa: quien manda es el numero mas alto
	ret c			;514e   ; y si es menor, se queda como estaba
L_514F:
	add a,a			;514f   ; el indice se dobla porque la tabla es de palabras
	ld de,05337h		;5150   ; la base de la tabla de melodias
	call suma_a_de		;5153   ; mas el indice doblado
	dec hl			;5156   ; retrocede a los dos bytes de control del canal
	dec hl			;5157   ; dos bytes atras: los de control del canal
L_5158:
	ld (hl),001h		;5158   ; duracion 1: que empiece en el cuadro siguiente
	inc hl			;515a   ; el byte siguiente
	ld (hl),001h		;515b   ; duracion 1 tambien
	inc hl			;515d   ; el siguiente
	ld (hl),c			;515e   ; y anota el numero, que es la prioridad
	inc hl			;515f   ; y el siguiente
	ld a,(de)			;5160   ; el puntero al guion de la melodia, byte a byte
	ld (hl),a			;5161   ; el numero de melodia, que hara de prioridad
	inc hl			;5162   ; el siguiente
	inc de			;5163   ; y el byte alto del guion
	ld a,(de)			;5164   ; leido
	ld (hl),a			;5165   ; y guardado
	ld a,00bh		;5166   ; cada canal ocupa 11 bytes
	call suma_a_hl		;5168   ; al bloque del canal siguiente
	inc de			;516b   ; y a su entrada de la tabla
	djnz L_5158		;516c   ; y se repite para los dos o tres canales
	ret			;516e   ; hecho

; ----------------------------------------------------------------------
; ===== El mezclador =====
; ----------------------------------------------------------------------
pon_el_mezclador:		; abre o cierra el tono y el ruido del canal C en el registro 7
	ld a,(0e03dh)		;516f   ; (0xE03D) es la copia del registro 7, que no se puede leer del PSG
	ld e,a			;5172   ; la copia del registro 7
	ld a,c			;5173   ; el canal
	cp 001h		;5174   ; el canal 1 no necesita desplazar
	jr z,L_5179		;5176   ; el primero no se desplaza
	dec a			;5178   ; y los demas, uno menos
L_5179:
	rlca			;5179   ; tres bits por canal
	rlca			;517a   ; tres bits
	rlca			;517b   ; por canal
	dec d			;517c   ; D distinto de 1 es cerrar
	jr z,L_5183		;517d   ; y a uno, abrir
	cpl			;517f   ; con D distinto de 1, se APAGA el bit
	and e			;5180   ; cerrar es borrar el bit
	jr L_5184		;5181
L_5183:
	or e			;5183   ; y si no, se enciende
L_5184:
	set 2,a		;5184   ; el bit 2 apaga el tono del tercer canal
	bit 5,a		;5186   ; el bit 5, el ruido del tercer canal
	jr z,escribe_el_mezclador		;5188   ; sin el, se escribe tal cual
	res 2,a		;518a   ; y con el, se apaga el tono
escribe_el_mezclador:		; vuelca la copia de (0xE03D) al registro 7
	ld (0e03dh),a		;518c   ; la copia, guardada
	ld e,a			;518f   ; y al registro
	ld a,007h		;5190   ; el 7, el del mezclador
	jp 00093h		;5192   ; BIOS WRTPSG - Writes data to PSG-register

; ----------------------------------------------------------------------
; ===== El latido del sonido =====
; ----------------------------------------------------------------------
late_el_sonido:		; una pasada por los tres canales, una vez por cuadro
	ld a,(0e03dh)		;5195   ; la copia del registro 7
	call escribe_el_mezclador		;5198   ; primero deja el mezclador como quedo
	ld c,001h		;519b   ; el canal 1
	ld ix,0e010h		;519d   ; el bloque de estado del primer canal
	exx			;51a1   ; al juego alterno, donde va la cuenta de canales
	ld b,003h		;51a2   ; tres canales
	ld de,0000fh		;51a4   ; y cada bloque esta 15 bytes mas alla
L_51A7:
	exx			;51a7   ; y de vuelta
	ld a,(ix+002h)		;51a8   ; (ix+2) a cero es canal libre
	or a			;51ab   ; cero es canal libre
	jr nz,L_51B3		;51ac   ; y ocupado, se sigue su melodia
	call calla_el_canal		;51ae   ; libre: silencio
	jr L_51B6		;51b1   ; con el libre, silencio
L_51B3:
	call sigue_la_melodia		;51b3   ; ocupado: seguir la melodia
L_51B6:
	inc c			;51b6   ; dos registros del PSG por canal
	inc c			;51b7   ; el canal siguiente: los registros van de dos en dos
	exx			;51b8   ; al juego alterno
	add ix,de		;51b9   ; el bloque del canal siguiente, quince bytes mas alla
	djnz L_51A7		;51bb   ; los tres canales
	ret			;51bd   ; hecho
sigue_la_melodia:		; gasta un cuadro del canal y ejecuta lo que toque del guion
	bit 6,a		;51be   ; el bit 6 de la copia del registro 7
	ld d,001h		;51c0   ; abrir
	call z,pon_el_mezclador		;51c2   ; y si no estaba, se abre el paso del canal
	ld a,(ix+002h)		;51c5   ; el estado del canal
	or a			;51c8   ; mirado
	jp m,L_528F		;51c9   ; con el bit 7 puesto, el canal esta en un efecto
	dec (ix+000h)		;51cc   ; la duracion de la nota
	ret nz			;51cf   ; mientras dure, no se lee nada mas del guion
L_51D0:
	ld l,(ix+003h)		;51d0   ; el puntero dentro del guion
	ld h,(ix+004h)		;51d3   ; y su byte alto
	ld a,(hl)			;51d6   ; el mandato por el que va
	cp 0feh		;51d7   ; 0xFE y 0xFF cierran
	jp nc,calla_el_canal		;51d9   ; 0xFE y 0xFF cierran la melodia
	bit 7,(ix+002h)		;51dc   ; el bit 7 del estado: el canal esta en un efecto
	jp nz,L_52B9		;51e0   ; y entonces se lee por otro camino

; ----------------------------------------------------------------------
; ===== Los mandatos del guion de melodia =====
; ----------------------------------------------------------------------
	cp 020h		;51e3   ; el 0x20 pelado es "usa envolvente"
	jp nz,L_5208		;51e5   ; si no es 0x20 pelado, es otra cosa
	ld (ix+00bh),001h		;51e8   ; y entonces el volumen lo lleva el hardware
	inc hl			;51ec   ; el byte siguiente
	ld a,(hl)			;51ed   ; leido
	ld e,a			;51ee   ; y al registro
	ld a,00ch		;51ef   ; registro 12 del PSG: la parte alta del periodo de la envolvente
	call 00093h		;51f1   ; BIOS WRTPSG - Writes data to PSG-register
	inc hl			;51f4   ; el siguiente
	ld a,(hl)			;51f5   ; leido
	ld e,a			;51f6   ; y al registro
	ld a,00bh		;51f7   ; registro 11: la parte baja
	call 00093h		;51f9   ; BIOS WRTPSG - Writes data to PSG-register
	inc hl			;51fc   ; el siguiente
	ld a,(hl)			;51fd   ; leido
	and 00fh		;51fe   ; solo el nibble bajo, que es lo que cabe
	ld e,a			;5200   ; y al registro
	ld a,00dh		;5201   ; registro 13: la FORMA de la envolvente
	call 00093h		;5203   ; BIOS WRTPSG - Writes data to PSG-register
	jr L_5214		;5206   ; y al remate
L_5208:
	and 0f0h		;5208   ; con el nibble alto a 2, lo que trae es una duracion
	cp 020h		;520a   ; nibble alto 2
	ld a,(hl)			;520c   ; el byte
	jr nz,L_5216		;520d   ; y si no lo es, a mirar el siguiente caso
	and 00fh		;520f   ; el nibble bajo, que es la duracion
	ld (ix+001h),a		;5211   ; y se guarda en (ix+1), que es de donde salen las notas siguientes
L_5214:
	inc hl			;5214   ; el byte siguiente
	ld a,(hl)			;5215   ; leido
L_5216:
	ld b,a			;5216   ; y guardado
	and 0f0h		;5217   ; nibble alto 1: ruido
	cp 010h		;5219   ; nibble alto 1: ruido
	jr nz,L_523E		;521b   ; y si no, al caso siguiente
	ld a,(hl)			;521d   ; el byte
	and 01fh		;521e   ; los cinco bits bajos son el periodo del ruido
	ld e,a			;5220   ; al registro
	ld a,c			;5221   ; el canal
	cp 005h		;5222   ; el canal 3 es el unico que lo usa asi
	jr nz,L_5233		;5224   ; solo el tercero lleva la correccion
	inc hl			;5226   ; el byte siguiente
	bit 4,(hl)		;5227   ; el bit 4 decide si el periodo se corrige
	ld b,(hl)			;5229   ; guardado
	jr nz,L_5230		;522a   ; con el bit 4 puesto, no se corrige
	ld a,e			;522c   ; el periodo
	sub 010h		;522d   ; menos 0x10: la correccion del ruido
	ld e,a			;522f   ; devuelto
L_5230:
	res 4,b		;5230   ; y se apaga el bit que la pedia
	dec hl			;5232   ; al byte anterior
L_5233:
	ld a,006h		;5233   ; registro 6: el periodo del ruido
	call 00093h		;5235   ; BIOS WRTPSG - Writes data to PSG-register
	ld d,000h		;5238   ; y se abre el paso del ruido en el mezclador
	call pon_el_mezclador		;523a   ; con D a cero, se cierra el paso
	inc hl			;523d   ; y al byte siguiente
L_523E:
	bit 6,(ix+002h)		;523e   ; el bit 6 de (ix+2) es el modo especial del canal
	jr z,L_5255		;5242   ; sin el bit, se sigue por lo normal
	ld a,c			;5244   ; el canal
	cp 005h		;5245   ; solo el tercero
	ld a,(hl)			;5247   ; el byte del guion
	jr nz,L_5255		;5248   ; y si no es el tercero, tampoco
	call guarda_el_guion		;524a   ; se anota por donde va el guion
	ld a,b			;524d   ; el valor guardado
	dec (ix+00bh)		;524e   ; un paso menos de la nota
	jr z,L_526D		;5251   ; y al agotarse, se apaga
	jr L_5272		;5253   ; y si queda, se recarga
L_5255:
	and 0f0h		;5255   ; el nibble alto
	ld b,a			;5257   ; guardado
	xor (hl)			;5258   ; el XOR separa el nibble bajo, quedando el alto en B
	ld d,a			;5259   ; y el bajo, que sale del XOR
	inc hl			;525a   ; el byte siguiente
	ld e,(hl)			;525b   ; que es el otro medio periodo
	call guarda_el_guion		;525c   ; guarda el guion por donde va
	ex de,hl			;525f   ; a HL, que es donde lo quiere la rutina de tono
	call pon_el_tono		;5260   ; y suelta el periodo, aqui tomado tal cual y no de la tabla de notas
	ld a,b			;5263   ; el nibble alto
	rrca			;5264   ; los cuatro desplazamientos suben el nibble alto al bajo
	rrca			;5265   ; tres desplazamientos
	rrca			;5266   ; lo bajan
	rrca			;5267   ; al nibble de las unidades
	dec (ix+00bh)		;5268   ; gasta un paso de la nota
	jr nz,L_5272		;526b   ; si aun queda nota, se sigue
L_526D:
	add a,010h		;526d   ; 0x10 mas: el escalon de volumen
	ld h,a			;526f   ; al registro
	jr pon_el_volumen		;5270   ; y se escribe
L_5272:
	ld h,a			;5272   ; el volumen
	ld a,(ix+001h)		;5273   ; recarga la duracion de (ix+1)
	ld (ix+000h),a		;5276   ; recarga la duracion
	add a,003h		;5279   ; tres cuadros mas
	ld (ix+008h),a		;527b   ; tres cuadros mas para el corte de la nota
	jr pon_el_volumen		;527e   ; y a escribir el volumen
calla_el_canal:		; cierra el mezclador y deja el canal libre
	ld d,001h		;5280   ; D a uno para cerrar el paso del canal
	call pon_el_mezclador		;5282   ; D=1 abre... aqui cierra: el canal queda mudo
	xor a			;5285   ; cero
	ld (ix+002h),a		;5286   ; (ix+2) a cero: canal libre
	ld (ix+00bh),a		;5289   ; en el paso de la nota
	ld h,a			;528c   ; y volumen cero
	jr pon_el_volumen		;528d   ; que se escribe
L_528F:
	dec (ix+000h)		;528f   ; un cuadro menos
	jp z,L_51D0		;5292   ; y al agotarse, se lee el guion
	dec (ix+008h)		;5295   ; (ix+8) es el corte de la nota
	ld a,(ix+008h)		;5298   ; el corte
	cp (ix+000h)		;529b   ; cuando alcanza a la duracion, la nota se apaga
	jr nz,L_52A5		;529e   ; mientras no alcance a la duracion, sigue bajando
	cp 003h		;52a0   ; por debajo de tres
	jr c,L_52A8		;52a2   ; se apaga del todo
	ret			;52a4   ; y si no, se deja como esta
L_52A5:
	dec (ix+008h)		;52a5   ; un paso mas del corte
L_52A8:
	ld a,(ix+007h)		;52a8   ; (ix+7) es el volumen, que va bajando solo
	dec a			;52ab   ; uno menos: el volumen decae solo
	ret m			;52ac   ; por debajo de cero no baja: la nota ya esta muerta
	ld (ix+007h),a		;52ad   ; guardado
	ld h,a			;52b0   ; y al registro

; ----------------------------------------------------------------------
; ===== El volumen =====
; ----------------------------------------------------------------------
pon_el_volumen:		; escribe H en el registro de volumen del canal C
	ld a,c			;52b1   ; el canal
	rrca			;52b2   ; C vale 1, 3 o 5, y esta cuenta lo convierte en el registro 8, 9 o 10
	add a,088h		;52b3   ; y esta cuenta lo convierte en su registro de volumen
	ld e,h			;52b5   ; el valor
	jp 00093h		;52b6   ; BIOS WRTPSG - Writes data to PSG-register

; ----------------------------------------------------------------------
; ===== Los mandatos que ajustan y no suenan =====
; ----------------------------------------------------------------------
L_52B9:
	ld a,(hl)			;52b9   ; el byte del guion
	and 0f0h		;52ba   ; solo el nibble alto
	cp 0d0h		;52bc   ; nibble alto D: cambia el multiplicador de duracion
	ld a,(hl)			;52be   ; el byte entero otra vez
	jr nz,L_52C8		;52bf   ; si no era D, al caso siguiente
	and 00fh		;52c1   ; el nibble bajo
	ld (ix+00ah),a		;52c3   ; (ix+0x0A), por el que se multiplican las duraciones que vengan
	inc hl			;52c6   ; el byte siguiente
	ld a,(hl)			;52c7   ; leido
L_52C8:
	cp 0f0h		;52c8   ; nibble alto F: el volumen de arranque
	jr c,L_52D3		;52ca   ; por debajo de 0xF0 no es este caso
	and 00fh		;52cc   ; el nibble bajo
	ld (ix+006h),a		;52ce   ; en (ix+6): el volumen de arranque
	inc hl			;52d1   ; el byte siguiente
	ld a,(hl)			;52d2   ; leido
L_52D3:
	cp 0e0h		;52d3   ; nibble alto E: la octava
	jr c,L_52DE		;52d5   ; por debajo de 0xE0 tampoco
	and 00fh		;52d7   ; el nibble bajo
	ld (ix+005h),a		;52d9   ; (ix+5), que es cuantas veces se duplica el periodo
	inc hl			;52dc   ; el byte siguiente
	ld a,(hl)			;52dd   ; que ya es la nota
L_52DE:
	and 00fh		;52de   ; lo que queda es el nibble bajo: cuantas veces se suma el multiplicador
	ld b,a			;52e0   ; la cuenta de sumas
	ld a,(ix+00ah)		;52e1   ; el multiplicador de duracion
	jr z,L_52EB		;52e4   ; sin cuenta, se queda como esta
L_52E6:
	add a,(ix+00ah)		;52e6   ; la duracion sale de sumar el multiplicador tantas veces
	djnz L_52E6		;52e9   ; y si no, se suma tantas veces
L_52EB:
	ld (ix+001h),a		;52eb   ; y se guarda como duracion del canal

; ----------------------------------------------------------------------
; ===== Y la nota =====
; ----------------------------------------------------------------------
	ld a,(hl)			;52ee   ; el byte de la nota
	call guarda_el_guion		;52ef   ; primero deja anotado por donde va el guion
	and 0f0h		;52f2   ; el nibble alto
	rrca			;52f4   ; el nibble alto es la nota, del 0 al 12
	rrca			;52f5   ; tres desplazamientos
	rrca			;52f6   ; lo bajan
	rrca			;52f7   ; a las unidades
	ld b,a			;52f8   ; guardado: es el numero de nota
	sub 00ch		;52f9   ; el 12 es el silencio: no toca nota, solo deja pasar el tiempo
	jr z,L_5300		;52fb   ; el 12 es silencio, y entonces no se toca volumen
	ld a,(ix+006h)		;52fd   ; y si suena, el volumen arranca del de (ix+6)
L_5300:
	ld (ix+007h),a		;5300   ; el volumen de arranque, a su sitio
	call L_5272		;5303   ; recarga la duracion
	ld a,b			;5306   ; la nota
	ld hl,0532dh		;5307   ; la tabla de los doce periodos
	call suma_a_hl		;530a   ; sumada a la tabla de periodos
	ld l,(hl)			;530d   ; un solo byte: la octava mas aguda cabe en ocho bits
	ld h,000h		;530e   ; y el byte alto a cero: cabe en ocho bits
	ld a,(ix+005h)		;5310   ; (ix+5) es la octava
	or a			;5313
	jr z,pon_el_tono		;5314
	ld b,a			;5316
L_5317:
	add hl,hl			;5317   ; y cada duplicacion del periodo baja una octava
	djnz L_5317		;5318

; ----------------------------------------------------------------------
; ===== Los dos registros de tono =====
; ----------------------------------------------------------------------
pon_el_tono:		; parte alta y baja del periodo, a los dos registros del canal
	ld a,c			;531a
	ld e,h			;531b   ; el byte alto primero
	call 00093h		;531c   ; BIOS WRTPSG - Writes data to PSG-register
	ld a,c			;531f
	dec a			;5320   ; y el registro de debajo lleva el bajo
	ld e,l			;5321
	jp 00093h		;5322   ; BIOS WRTPSG - Writes data to PSG-register
guarda_el_guion:		; deja en (ix+3) por donde va el guion de este canal
	inc hl			;5325
	ld (ix+003h),l		;5326
	ld (ix+004h),h		;5329
	ret			;532c

; ----------------------------------------------------------------------
; DATOS periodos_del_psg: 12 semitonos de la octava mas aguda: 106, 100, 95,
;   89, 84, 80, 75, 71, 67, 63, 60 y 56. Las octavas graves se sacan
;   duplicando
;   0x532d..0x5339  (12 bytes)
DATA_periodos_del_psg:
	defb 06ah	; 532d
	defb 064h	; 532e
	defb 05fh	; 532f
	defb 059h	; 5330
	defb 054h	; 5331
	defb 050h	; 5332
	defb 04bh	; 5333
	defb 047h	; 5334
	defb 043h	; 5335
	defb 03fh	; 5336
	defb 03ch	; 5337
	defb 038h	; 5338

; ----------------------------------------------------------------------
; DATOS tabla_de_melodias: 54 entradas; la indexa 0x5150 con base 0x5337 desde
;   el indice 1. La primera apunta a 0x53A5, justo detras
;   0x5339..0x53a5  (108 bytes)
DATA_tabla_de_melodias:
	defw 053a5h,053a9h,053b0h,053b7h,053cah,053dah,053eah,053f4h	; 5339
	defw 0540ah,05414h,05418h,05426h,0542dh,05441h,05455h,05485h	; 5349
	defw 054b6h,054d8h,054f3h,0552fh,05536h,05545h,0554ch,0555bh	; 5359
	defw 05562h,05566h,0556eh,05575h,05579h,05581h,05588h,05599h	; 5369
	defw 055a0h,055a7h,055b8h,055bfh,055c6h,05602h,0561dh,0563bh	; 5379
	defw 0568ch,056d9h,056f9h,05717h,0572ah,0572bh,0573bh,05753h	; 5389
	defw 0576eh,0578fh,057afh,057c8h,057c8h,057c8h	; 5399

; ----------------------------------------------------------------------
; DATOS melodias: 1060 bytes de guiones para el PSG; las 54 entradas de la
;   tabla caen todas aqui dentro, y tres de ellas en el ultimo byte
;   0x53a5..0x57c9  (1060 bytes)
DATA_melodias:
	defb 021h,0d0h,090h,0ffh,020h,000h,012h,009h,017h,00fh,0ffh,020h,000h,044h,009h,0f0h	; 53a5  !... ...... .D..
	defb 055h,0ffh,0d2h,0fch,0e1h,020h,0d4h,0e0h,020h,0d3h,0c0h,0fah,020h,0c0h,0f8h,020h	; 53b5  U.... .. ... .. 
	defb 0c0h,0f6h,020h,0c0h,0ffh,021h,0c1h,000h,022h,000h,000h,021h,0c0h,03ah,0b0h,040h	; 53c5  .. ..!.."..!.:.@
	defb 0a0h,045h,090h,04ah,0ffh,021h,0d3h,000h,0c2h,0e8h,0b2h,0d0h,0a2h,0b8h,092h,0a0h	; 53d5  .E.J.!..........
	defb 082h,088h,072h,060h,0ffh,024h,0a0h,055h,022h,000h,000h,024h,0b0h,070h,0ffh,021h	; 53e5  ..r`.$.U"..$.p.!
	defb 0d0h,048h,025h,000h,000h,021h,0c0h,050h,0a0h,054h,090h,058h,080h,05ch,070h,061h	; 53f5  .H%..!.P.T.X.\pa
	defb 060h,067h,050h,06dh,0ffh,021h,0a0h,048h,090h,054h,080h,05ah,0b0h,060h,0ffh,023h	; 5405  `gPm.!.H.T.Z.`.#
	defb 0a0h,053h,0ffh,023h,0a0h,060h,021h,080h,064h,060h,068h,050h,06ch,027h,0a0h,070h	; 5415  .S.#.`!.d`hPl'.p
	defb 0ffh,027h,000h,000h,024h,090h,085h,0ffh,022h,082h,000h,000h,000h,091h,000h,000h	; 5425  .'..$...".......
	defb 000h,090h,080h,000h,000h,060h,040h,000h,000h,050h,01fh,0ffh,021h,091h,000h,000h	; 5435  .....`@..P..!...
	defb 000h,090h,080h,000h,000h,090h,040h,000h,000h,060h,01fh,000h,000h,050h,010h,0ffh	; 5445  ......@..`...P..
	defb 024h,0a0h,060h,0b0h,050h,0b0h,040h,0b0h,030h,0b0h,020h,025h,000h,000h,023h,0a0h	; 5455  $.`.P.@.0. %..#.
	defb 020h,025h,000h,000h,022h,090h,020h,025h,000h,000h,022h,080h,020h,026h,000h,000h	; 5465   %..". %..". &..
	defb 022h,070h,020h,026h,000h,000h,022h,060h,020h,027h,000h,000h,022h,050h,020h,0ffh	; 5475  "p &.."` '.."P .
	defb 022h,000h,000h,024h,0a0h,040h,0b0h,030h,0b0h,020h,0b0h,010h,025h,000h,000h,023h	; 5485  "..$.@.0. ..%..#
	defb 0a0h,010h,025h,000h,000h,022h,090h,010h,025h,000h,000h,022h,080h,010h,026h,000h	; 5495  ..%.."..%.."..&.
	defb 000h,022h,070h,010h,026h,000h,000h,022h,060h,010h,027h,000h,000h,022h,050h,010h	; 54a5  ."p.&.."`.'.."P.
	defb 0ffh,022h,0c0h,035h,000h,000h,0c0h,020h,000h,000h,0c0h,01ah,023h,000h,000h,090h	; 54b5  .".5... ....#...
	defb 01ah,000h,000h,080h,01ah,000h,000h,024h,070h,01ah,000h,000h,060h,01ah,000h,000h	; 54c5  .......$p...`...
	defb 050h,01ah,0ffh,022h,090h,035h,000h,000h,090h,043h,023h,000h,000h,070h,043h,000h	; 54d5  P..".5...C#..pC.
	defb 000h,024h,060h,043h,000h,000h,050h,043h,000h,000h,025h,040h,043h,0ffh,021h,0c0h	; 54e5  .$`C..PC..%@C.!.
	defb 050h,025h,000h,000h,022h,081h,04bh,081h,045h,081h,040h,081h,03bh,091h,035h,091h	; 54f5  P%..".K.E.@.;.5.
	defb 030h,091h,02bh,091h,025h,091h,020h,091h,01bh,091h,015h,091h,010h,0a1h,00bh,025h	; 5505  0.+.%. ........%
	defb 0a1h,008h,022h,0a1h,00bh,091h,010h,091h,015h,091h,01bh,091h,020h,091h,025h,091h	; 5515  .."......... .%.
	defb 02bh,081h,033h,081h,03bh,081h,043h,081h,04bh,0ffh,020h,000h,0a0h,009h,0f0h,01fh	; 5525  +.3.;.C.K. .....
	defb 0ffh,021h,0c0h,058h,025h,000h,000h,021h,0a0h,057h,070h,056h,023h,060h,058h,0ffh	; 5535  .!.X%..!.WpV#`X.
	defb 020h,000h,0a0h,009h,0f0h,01fh,0ffh,021h,0d0h,05dh,025h,000h,000h,021h,0a0h,05bh	; 5545   ......!.]%..!.[
	defb 080h,05ah,023h,060h,05ch,0ffh,020h,000h,0f8h,009h,0f0h,05fh,0ffh,021h,0c0h,058h	; 5555  .Z#`\. ...._.!.X
	defb 0ffh,020h,000h,0a0h,009h,01fh,0f0h,01fh,0ffh,020h,000h,077h,009h,01fh,00fh,0ffh	; 5565  . ....... .w....
	defb 021h,0c0h,05dh,0ffh,020h,000h,055h,009h,01fh,0f0h,020h,0ffh,020h,000h,088h,009h	; 5575  !.]. .U... . ...
	defb 01fh,00fh,0ffh,021h,0d0h,03ch,023h,000h,000h,021h,0b0h,03bh,090h,03ah,070h,03bh	; 5585  ...!.<#..!.;.:p;
	defb 023h,060h,03dh,0ffh,020h,000h,0a0h,009h,0f0h,01fh,0ffh,020h,001h,033h,009h,010h	; 5595  #`=. ...... .3..
	defb 00fh,0ffh,021h,0f0h,040h,023h,000h,000h,021h,0b0h,03fh,090h,03dh,080h,03fh,023h	; 55a5  ..!.@#..!.?.=.?#
	defb 060h,041h,0ffh,020h,000h,0f8h,009h,0f0h,020h,0ffh,020h,001h,066h,009h,010h,00fh	; 55b5  `A. .... . .f...
	defb 0ffh,0d3h,0fch,0e2h,020h,040h,0d7h,050h,0c0h,050h,050h,000h,050h,092h,052h,070h	; 55c5  .... @.P.PP.P.Rp
	defb 0c0h,070h,070h,040h,070h,0a2h,091h,0d4h,070h,0a0h,0d3h,0f9h,0e0h,000h,020h,000h	; 55d5  .pp@p...p..... .
	defb 020h,000h,020h,000h,020h,000h,020h,000h,020h,000h,020h,000h,020h,000h,020h,000h	; 55e5   . . . . . . . .
	defb 020h,000h,020h,000h,020h,000h,020h,0d7h,0fah,0e1h,0a0h,097h,0ffh,0d7h,0fbh,0e2h	; 55f5   . . . .........
	defb 0c0h,001h,000h,000h,0e3h,090h,0e2h,000h,052h,002h,041h,040h,040h,000h,040h,072h	; 5605  ........R.A@@.@r
	defb 042h,0e1h,004h,000h,004h,000h,057h,0ffh,0d3h,0fch,0e3h,0c1h,0d7h,052h,001h,0c0h	; 5615  B.....W......R..
	defb 051h,0c0h,002h,042h,002h,071h,0c0h,002h,0fbh,091h,0a0h,091h,0a0h,0e2h,001h,0e3h	; 5625  Q..B.q..........
	defb 0b0h,0e2h,001h,040h,057h,0ffh,022h,01fh,080h,022h,080h,023h,080h,024h,021h,090h	; 5635  ...@W."..".#.$!.
	defb 025h,090h,027h,090h,029h,090h,02bh,090h,02ch,022h,090h,022h,090h,023h,090h,024h	; 5645  %.'.).+.,".".#.$
	defb 021h,090h,025h,0a0h,027h,0a0h,029h,0a0h,02bh,0a0h,02ch,022h,0a0h,01fh,0a0h,020h	; 5655  !.%.'.).+.,"... 
	defb 0a0h,021h,021h,0a0h,022h,0a0h,024h,0a0h,026h,0a0h,028h,0a0h,02ah,02fh,0b0h,001h	; 5665  .!!.".$.&.(.*/..
	defb 0b0h,001h,0b0h,001h,0a0h,001h,026h,090h,001h,080h,001h,070h,001h,060h,001h,024h	; 5675  ......&....p.`.$
	defb 050h,001h,040h,001h,030h,001h,0ffh,02ah,000h,000h,022h,080h,022h,080h,023h,080h	; 5685  P.@.0..*..".".#.
	defb 024h,021h,080h,025h,080h,027h,080h,029h,080h,02bh,080h,02ch,022h,080h,022h,080h	; 5695  $!.%.'.).+.,".".
	defb 023h,080h,024h,021h,080h,025h,080h,027h,080h,029h,080h,02bh,080h,02ch,022h,080h	; 56a5  #.$!.%.'.).+.,".
	defb 020h,080h,021h,080h,022h,021h,080h,024h,080h,026h,080h,028h,080h,02ah,026h,080h	; 56b5   .!."!.$.&.(.*&.
	defb 024h,000h,000h,022h,080h,035h,080h,036h,080h,033h,021h,080h,032h,080h,030h,080h	; 56c5  $..".5.6.3!.2.0.
	defb 02eh,080h,02ch,0ffh,023h,01fh,006h,000h,007h,000h,007h,000h,007h,000h,007h,000h	; 56d5  ..,.#...........
	defb 007h,000h,006h,000h,006h,000h,005h,000h,005h,000h,004h,000h,004h,000h,003h,000h	; 56e5  ................
	defb 002h,000h,001h,0ffh,021h,070h,055h,027h,0a0h,050h,021h,080h,053h,070h,056h,070h	; 56f5  ....!pU'.P!.SpVp
	defb 05bh,070h,060h,026h,0a0h,0a0h,021h,080h,0a5h,070h,0aah,060h,0b0h,050h,0b5h,040h	; 5705  [p`&..!..p.`.P.@
	defb 0bah,0ffh,021h,070h,070h,027h,090h,065h,021h,060h,068h,060h,06bh,060h,070h,060h	; 5715  ..!pp'.e!`h`k`p`
	defb 075h,026h,070h,0c0h,0ffh,0ffh,0d8h,0fch,0e2h,001h,020h,044h,050h,042h,0e1h,000h	; 5725  u&p....... DPB..
	defb 0e2h,0b0h,090h,0e1h,048h,0ffh,0d4h,0fbh,0e2h,043h,051h,0fah,071h,070h,070h,071h	; 5735  ....H....CQ.qppq
	defb 071h,0fbh,071h,0e1h,001h,0e2h,075h,091h,071h,051h,0d8h,0e1h,008h,0ffh,0d4h,0fch	; 5745  q.q...u.qQ......
	defb 0e3h,003h,021h,0e2h,003h,0c1h,0e3h,0b3h,0c1h,093h,0c1h,071h,071h,071h,0e2h,004h	; 5755  ..!........qqq..
	defb 0c0h,0e3h,072h,0d5h,070h,071h,0e2h,003h,0ffh,0d7h,0fch,0e2h,0c2h,000h,000h,020h	; 5765  ..r.pq......... 
	defb 040h,0d4h,057h,0c1h,090h,080h,091h,0c1h,0e1h,001h,0e2h,051h,0c1h,091h,001h,0e3h	; 5775  @.W........Q....
	defb 0b1h,0e2h,001h,021h,0c1h,041h,051h,0cdh,0cdh,0ffh,0d7h,0fah,0e3h,0c2h,090h,090h	; 5785  ...!.AQ.........
	defb 0a0h,0e2h,000h,0d4h,0e1h,003h,050h,040h,051h,0c1h,050h,040h,051h,0c1h,091h,091h	; 5795  ......P@Q.P@Q...
	defb 071h,051h,0e1h,007h,0c1h,001h,051h,0cdh,0cdh,0ffh,0d7h,0fbh,0e3h,0c3h,000h,020h	; 57a5  qQ....Q........ 
	defb 040h,0d4h,0fch,053h,051h,043h,041h,023h,021h,003h,001h,003h,001h,023h,041h,051h	; 57b5  @..SQCA#!....#AQ
	defb 0cdh,0cdh,0ffh,0ffh	; 57c5

; ======================================================================
; CODIGO 0x57c9..0x5886  (189 bytes)
; ======================================================================



; ----------------------------------------------------------------------
; ===== PREPARAR A LOS DOS JUGADORES =====
; ----------------------------------------------------------------------
prepara_a_los_jugadores:		; borra el estado, reparte posiciones y saca los valores que dependen del nivel
	ld hl,0e100h		;57c9   ; 0x200 bytes de estado de juego, a cero
	ld de,0e101h		;57cc   ; a la siguiente, para propagar con `ldir`
	ld bc,00200h		;57cf   ; 0x200 bytes de estado
	ld (hl),000h		;57d2   ; un cero al principio
	ldir		;57d4   ; y se propaga
	ld hl,0e070h		;57d6   ; el buffer de sprites
	ld de,0e071h		;57d9   ; igual, a la siguiente
	ld bc,00080h		;57dc   ; 0x80 bytes: los 32 sprites
	ld (hl),0e0h		;57df   ; 0xE0 en los 0x80 bytes de atributos: todos los sprites, fuera de la pantalla
	ldir		;57e1   ; y se propaga el 0xE0
	ld a,(0e002h)		;57e3   ; el modo
	bit 5,a		;57e6   ; con dos jugadores no se toca el lado
	jr nz,L_57F5		;57e8   ; con dos jugadores no se toca el lado
	ld a,(0e053h)		;57ea   ; y con uno, solo en el primer set
	dec a			;57ed   ; el primer set
	jr nz,L_57F5		;57ee   ; y en los demas tampoco
	ld a,0ffh		;57f0   ; 0xFF: el lado de salida
	ld (0e140h),a		;57f2   ; (0xE140) a 0xFF: el lado de cada uno
L_57F5:
	ld hl,058c7h		;57f5   ; los mismos ocho bytes para los dos jugadores
	ld de,0e0b8h		;57f8   ; los ocho bytes del primero
	ld bc,00008h		;57fb   ; ocho
	ldir		;57fe   ; copiados
	ld hl,058c7h		;5800   ; los mismos otra vez
	ld de,0e09ch		;5803   ; el segundo, a 0xE09C
	ld bc,00008h		;5806   ; ocho
	ldir		;5809   ; y al segundo: los dos empiezan igual
	ld a,023h		;580b   ; el jugador cercano arranca en x=0x23
	ld hl,0e160h		;580d   ; el bloque del jugador cercano
	ld (hl),a			;5810   ; su x
	inc hl			;5811   ; el byte siguiente
	ld a,078h		;5812   ; y=0x78
	ld (hl),a			;5814   ; su y
	inc hl			;5815   ; el siguiente
	ld a,03ah		;5816   ; 0x3A
	ld (hl),a			;5818   ; y su tercera coordenada
	ld hl,058b3h		;5819   ; la tabla de pares indexada por el nivel
	ld a,(0e047h)		;581c   ; (0xE047) es el nivel: el elegido en el menu, o el 3 fijo en la demostracion
	add a,a			;581f   ; dos bytes por nivel
	call suma_a_hl		;5820   ; mas el nivel doblado
	ld b,(hl)			;5823   ; el primer byte del par
	inc hl			;5824   ; el siguiente
	ld a,(hl)			;5825   ; y el segundo
	ld de,0e16ah		;5826   ; y el par va a los dos jugadores por igual
	ld hl,0e18ah		;5829   ; el sitio del otro jugador
	ld (hl),a			;582c   ; al primero
	ld (de),a			;582d   ; y al segundo
	inc hl			;582e   ; el byte de al lado
	inc de			;582f   ; en los dos
	ld a,b			;5830   ; el otro del par
	ld (hl),a			;5831   ; al primero
	ld (de),a			;5832   ; y al segundo: los dos arrancan iguales
	ld a,0a0h		;5833   ; el lejano arranca en x=0xA0, al otro lado
	ld hl,0e180h		;5835   ; el bloque del jugador lejano
	ld (hl),a			;5838   ; su x, al otro lado de la mesa
	inc hl			;5839   ; el byte siguiente
	ld a,078h		;583a   ; 0x78, media altura
	ld (hl),a			;583c   ; guardada
	inc hl			;583d   ; el siguiente
	ld a,03ah		;583e   ; 0x3A
	ld (hl),a			;5840   ; y su tercera coordenada
	inc hl			;5841   ; el siguiente
	ld a,(0e047h)		;5842   ; el nivel
	ld b,a			;5845   ; guardado
	add a,a			;5846   ; aqui el nivel cuenta de tres en tres
	push af			;5847   ; y el doble, que hace falta luego
	add a,b			;5848   ; mas el propio nivel: tres veces
	ld hl,05886h		;5849   ; ocho bytes desde 0x5886 + 3 veces el nivel: los tramos se SOLAPAN
	call suma_a_hl		;584c   ; sumado a la tabla
	ld de,0e1a1h		;584f   ; el destino
	ld bc,00008h		;5852   ; ocho bytes
	ldir		;5855   ; copiados
	pop af			;5857   ; se recupera el nivel doblado
	push af			;5858   ; y el nivel doblado se guarda para las dos tablas siguientes
	ld hl,058bdh		;5859   ; la tabla de pares
	call suma_a_hl		;585c   ; mas el indice
	ld de,0e11ah		;585f   ; el destino
	ld a,(hl)			;5862   ; el mismo byte va a las dos posiciones: los dos jugadores empiezan igual
	ld (de),a			;5863   ; escrito
	inc hl			;5864   ; el byte siguiente de la tabla
	inc de			;5865   ; y el de al lado del destino
	ld (de),a			;5866   ; donde va el MISMO valor: el `inc hl` no llega a usarse
	pop af			;5867   ; el nivel doblado otra vez
	ld hl,058aeh		;5868   ; la tabla de un byte por nivel
	call suma_a_hl		;586b   ; mas el indice
	ld a,(hl)			;586e   ; el valor
	ld (0e1a9h),a		;586f   ; a su sitio
	call L_5DEB		;5872   ; y por ultimo, los colores de los sprites
	ld hl,058cfh		;5875   ; los colores de sprite
	ld de,0e0c0h		;5878   ; al buffer
	ld bc,00008h		;587b   ; ocho
	ldir		;587e   ; copiados
	ld a,002h		;5880   ; dos
	ld (0e1a0h),a		;5882   ; (0xE1A0) a 2: el fotograma de partida
	ret			;5885   ; hecho

; ----------------------------------------------------------------------
; DATOS ajustes_por_nivel: 0x5849 copia OCHO bytes desde 0x5886 mas TRES veces
;   el nivel, asi que los cinco tramos se solapan
;   0x5886..0x58ae  (40 bytes)
DATA_ajustes_por_nivel:
	defb 02ah,0cfh,00ah,011h,0feh,003h,0fch,088h	; 5886  *.......
	defb 0aeh,0aeh,0afh,055h,0aah,065h,0fch,073h	; 588e  ...U.e.s
	defb 0eeh,0afh,0eah,0ffh,0a5h,0f1h,0b7h,0feh	; 5896  ........
	defb 0feh,0efh,0eeh,0f7h,07eh,0ffh,0bbh,0fbh	; 589e  ....~...
	defb 0ffh,0ffh,0feh,0ffh,0feh,0ffh,0feh,0ffh	; 58a6  ........

; ----------------------------------------------------------------------
; DATOS un_byte_por_nivel: 5 bytes, uno por nivel; 0x5868 saca el suyo y lo
;   deja en (0xE1A9)
;   0x58ae..0x58b3  (5 bytes)
DATA_un_byte_por_nivel:
	defb 0a1h	; 58ae
	defb 0aah	; 58af
	defb 0eah	; 58b0
	defb 0eeh	; 58b1
	defb 0feh	; 58b2

; ----------------------------------------------------------------------
; DATOS posiciones_por_nivel: 5 pares indexados por el nivel en 0x5819; el par
;   va igual a los dos jugadores
;   0x58b3..0x58bd  (10 bytes)
DATA_posiciones_por_nivel:
	defb 0aah,0eeh	; 58b3
	defb 0aah,0eeh	; 58b5
	defb 0eah,0feh	; 58b7
	defb 0eah,0feh	; 58b9
	defb 0eeh,0ffh	; 58bb

; ----------------------------------------------------------------------
; DATOS otro_par_por_nivel: 5 pares; de cada uno 0x5859 usa solo el primer
;   byte, y lo escribe DOS veces
;   0x58bd..0x58c7  (10 bytes)
DATA_otro_par_por_nivel:
	defb 057h,057h	; 58bd
	defb 077h,077h	; 58bf
	defb 0f7h,077h	; 58c1
	defb 0f7h,0f7h	; 58c3
	defb 0ffh,0ffh	; 58c5

; ----------------------------------------------------------------------
; DATOS atributos_de_sprite: los 8 bytes de arranque, que 0x57F5 y 0x5800
;   copian iguales a los dos jugadores
;   0x58c7..0x58cf  (8 bytes)
DATA_atributos_de_sprite:
	defb 0e0h	; 58c7
	defb 000h	; 58c8
	defb 000h	; 58c9
	defb 00fh	; 58ca
	defb 0e0h	; 58cb
	defb 000h	; 58cc
	defb 000h	; 58cd
	defb 001h	; 58ce

; ----------------------------------------------------------------------
; DATOS colores_de_sprite: 8 bytes que 0x5875 copia a 0xE0C0
;   0x58cf..0x58d7  (8 bytes)
DATA_colores_de_sprite:
	defb 047h	; 58cf
	defb 038h	; 58d0
	defb 050h	; 58d1
	defb 001h	; 58d2
	defb 047h	; 58d3
	defb 0b8h	; 58d4
	defb 054h	; 58d5
	defb 001h	; 58d6

; ======================================================================
; CODIGO 0x58d7..0x5c58  (897 bytes)
; ======================================================================



; ----------------------------------------------------------------------
; ===== EL CUADRO DE LA PARTIDA =====
; ----------------------------------------------------------------------
corre_el_punto:		; un cuadro de juego: mandos, jugadores, pelota y sprites
	ld a,(0e130h)		;58d7   ; (0xE130) es la fase del punto
	and a			;58da   ; la fase 0
	jr z,L_58E5		;58db   ; en ella no se mueve nadie
	cp 008h		;58dd   ; la 8
	jr z,L_58E5		;58df   ; tampoco
	cp 009h		;58e1   ; ni la 9
	jr nz,L_58F2		;58e3   ; y en las demas, los mandos valen
L_58E5:
	xor a			;58e5   ; cero
	ld (0e009h),a		;58e6   ; en esas fases se borran los mandos de los dos: nadie manda mientras
	ld (0e049h),a		;58e9   ; el mando crudo del segundo
	ld (0e008h),a		;58ec   ; los flancos del primero
	ld (0e048h),a		;58ef   ; y los del segundo: en esas fases nadie manda
L_58F2:
	ld a,(0e130h)		;58f2   ; y en estas otras tampoco se mueve a nadie
	and a			;58f5   ; la fase 0
	jr z,L_5910		;58f6   ; en ella no se mueve nadie
	cp 002h		;58f8   ; la 2
	jr z,L_5910		;58fa   ; tampoco
	cp 004h		;58fc   ; la 4
	jr z,L_5910		;58fe   ; tampoco
	cp 009h		;5900   ; y de la 9 en adelante
	jr nc,L_5910		;5902   ; tampoco
	call L_5E08		;5904   ; el jugador cercano
	call L_5E50		;5907   ; el lejano
	call vuelca_los_sprites		;590a   ; los sprites a la VRAM
	call dibuja_la_pelota		;590d   ; y la pelota
L_5910:
	call mueve_al_cercano		;5910   ; el jugador cercano
	call mueve_al_lejano		;5913   ; y el lejano
	jp reparte_la_subfase		;5916   ; el reparto de subfases del punto

; ----------------------------------------------------------------------
; ===== Los sprites a la pantalla =====
; ----------------------------------------------------------------------
vuelca_los_sprites:		; los 0x80 bytes de 0xE070 a la tabla de atributos, en 0x3B00
	ld hl,03b00h		;5919   ; 0x3B00 es donde R5 pone los atributos de sprite
	ld de,0e070h		;591c   ; el buffer de sprites
	ld bc,00080h		;591f   ; 32 sprites de cuatro bytes
	jp copia_a_vram		;5922   ; y se copia entero a la VRAM

; ----------------------------------------------------------------------
; ===== Mover al jugador cercano =====
; ----------------------------------------------------------------------
mueve_al_cercano:		; traduce su mando en direccion, y de ahi en fotograma
	ld ix,0e160h		;5925   ; su bloque de estado
	ld hl,0e009h		;5929   ; y su mando
	ld b,002h		;592c   ; dos bytes de mando
	call L_59D4		;592e   ; y se ajusta lo que se acaba de pulsar
	ld a,(0e165h)		;5931   ; (0xE165) distinto de cero: esta en mitad de un golpe, y manda la trayectoria
	and a			;5934   ; cero es que no esta golpeando
	ld hl,05ecfh		;5935   ; la tabla de trayectorias del cercano
	jp nz,L_59E0		;5938   ; y si lo esta, manda la trayectoria
	ld b,007h		;593b   ; siete
	ld c,0f9h		;593d   ; 0xF9: el patron de velocidad, seis cuadros de cada ocho
	ld hl,0e16ah		;593f   ; su posicion
	ld de,0e16bh		;5942   ; y la de al lado
	call persigue_la_pelota		;5945   ; y se le acerca a la pelota
	ld hl,0e008h		;5948   ; los flancos del primero
L_594B:
	ld a,(0e130h)		;594b   ; la fase del punto
	dec a			;594e   ; en la fase 1 solo se admiten dos de las direcciones
	jr nz,L_5955		;594f   ; fuera de la 1, el mando entero vale
	ld a,(hl)			;5951   ; el mando
	and 00ch		;5952   ; los bits 2 y 3, o sea izquierda y derecha
	ld (hl),a			;5954   ; y devuelto con solo las dos direcciones que la fase 1 admite
L_5955:
	ld b,002h		;5955   ; las dos coordenadas
L_5957:
	ld a,(ix+000h)		;5957   ; guarda la posicion de este cuadro, para saber luego cuanto se ha movido
	ld (ix+008h),a		;595a   ; guardadas en (ix+8), para saber luego cuanto se ha movido
	inc ix		;595d   ; a la coordenada siguiente
	djnz L_5957		;595f   ; las dos
	dec ix		;5961   ; y se devuelve IX
	dec ix		;5963   ; a donde estaba
	ld a,(ix+004h)		;5965   ; las banderas del muneco
	and 083h		;5968   ; deja solo los bits que sobreviven al cuadro
	ld (ix+004h),a		;596a   ; devueltas sin las que no sobreviven al cuadro
	ld de,0e130h		;596d   ; la fase del punto
	ld a,(de)			;5970   ; leida
	cp 001h		;5971   ; la 1
	jr nz,L_5978		;5973   ; fuera de ella, el mando entero
	inc de			;5975   ; el byte de al lado
	ld a,(de)			;5976   ; leido
	and a			;5977   ; y mirado
L_5978:
	ld a,(hl)			;5978   ; el mando
	jr nz,L_597D		;5979   ; con la condicion, entero
	and 0f7h		;597b   ; sin la condicion, tampoco se admite el bit 3
L_597D:
	rra			;597d   ; el mando se va desgranando bit a bit
	jr nc,L_5986		;597e   ; sin acarreo, esa direccion no se pulso
	set 5,(ix+004h)		;5980   ; arriba
	jr L_5997		;5984   ; y a rematar
L_5986:
	rra			;5986   ; el bit siguiente
	rra			;5987
	jr nc,L_5990		;5988
	set 4,(ix+004h)		;598a   ; abajo
	jr L_5997		;598e
L_5990:
	rra			;5990
	jr nc,L_59B0		;5991
	set 2,(ix+004h)		;5993   ; y el golpe
L_5997:
	ld de,0e130h		;5997   ; la fase del punto
	ld a,(de)			;599a   ; leida
	cp 001h		;599b   ; la 1
	jr nz,L_59A4		;599d   ; fuera de ella, se golpea
	inc de			;599f   ; el paso dentro de la fase
	ld a,(de)			;59a0   ; leido
	and a			;59a1   ; a cero
	jr z,L_59B0		;59a2   ; aun no se puede golpear
L_59A4:
	ld a,001h		;59a4   ; uno: se golpea
	ld (ix+005h),a		;59a6   ; (ix+5) a 1: empieza el movimiento
	xor a			;59a9   ; cero
	ld (ix+007h),a		;59aa   ; y el paso dentro de el, a cero
	inc (ix+011h)		;59ad   ; (ix+0x11) cuenta los golpes dados
L_59B0:
	res 1,(ix+004h)		;59b0   ; y se apaga el bit de correr
	ld a,(ix+00eh)		;59b4   ; (ix+0x0E): si esta puesto, el muneco va corriendo
	and a			;59b7
	jr z,L_59BE		;59b8
	set 1,(ix+004h)		;59ba
L_59BE:
	ld b,(ix+004h)		;59be   ; y ahora los bits de direccion se convierten en un numero
	xor a			;59c1
	rr b		;59c2
	rr b		;59c4
	jr nc,L_59CA		;59c6
	add a,00ah		;59c8   ; uno de los lados suma 10
L_59CA:
	rr b		;59ca
	jr nc,L_59D0		;59cc
	add a,005h		;59ce   ; y el otro 5: de ahi salen 0, 5, 10 y 15
L_59D0:
	ld (ix+003h),a		;59d0   ; (ix+3) es la direccion, que es lo que elige el fotograma
	ret			;59d3
L_59D4:
	ld a,(hl)			;59d4
	and 010h		;59d5
	ld a,000h		;59d7
	jr z,L_59DC		;59d9
	inc a			;59db
L_59DC:
	ld (ix+00eh),a		;59dc
	ret			;59df
L_59E0:
	cp 002h		;59e0   ; el estado 2 es "trayectoria plantada"
	jr nz,sigue_la_trayectoria		;59e2   ; y en los demas, se sigue el guion
	dec (ix+000h)		;59e4   ; un cuadro menos de la vuelta
	ld b,(ix+000h)		;59e7   ; lo que queda
	ld a,(ix+008h)		;59ea   ; contra donde empezo
	cp b			;59ed   ; comparados
	ret c			;59ee   ; y mientras no vuelva, no se hace nada
	xor a			;59ef   ; cero
	ld (ix+005h),a		;59f0   ; el estado del movimiento, a cero: se acabo
	ld a,(ix+004h)		;59f3   ; las banderas
	and 003h		;59f6   ; se quedan solo las dos de direccion
	ld (ix+004h),a		;59f8   ; y se devuelven
	ld a,(ix+008h)		;59fb   ; la posicion de partida
	ld (ix+000h),a		;59fe   ; que vuelve a ser la actual
	ld a,(ix+009h)		;5a01   ; y la otra coordenada
	ld (ix+001h),a		;5a04   ; tambien: el muneco queda donde empezo
	ret			;5a07   ; hecho

; ----------------------------------------------------------------------
; ===== Seguir una trayectoria =====
; ----------------------------------------------------------------------
sigue_la_trayectoria:		; saca del guion el desplazamiento de este cuadro y mueve al muneco
	push hl			;5a08
	ld a,(ix+004h)		;5a09   ; (ix+4) trae la direccion en bits
	and 007h		;5a0c   ; y esta cuenta la convierte en indice de la tabla de cuatro
	rra			;5a0e
	add a,a			;5a0f
	call suma_a_hl		;5a10
	ld e,(hl)			;5a13
	inc hl			;5a14
	ld d,(hl)			;5a15
	pop hl			;5a16
	ld a,(ix+007h)		;5a17   ; (ix+7) es el paso dentro de la secuencia
	call suma_a_de		;5a1a
	ld a,(de)			;5a1d
	cp 0a0h		;5a1e   ; el 0xA0 cierra la secuencia
	jr nz,L_5A2A		;5a20
	inc (ix+007h)		;5a22
	inc (ix+003h)		;5a25   ; al acabarse, se pasa a la direccion siguiente y se vuelve a probar
	jr sigue_la_trayectoria		;5a28
L_5A2A:
	cp 0aah		;5a2a   ; y el 0xAA la deja en espera
	jr z,L_5A43		;5a2c
	inc (ix+007h)		;5a2e   ; dos bytes por paso: uno de cada eje
	inc (ix+007h)		;5a31
	add a,(ix+008h)		;5a34   ; el desplazamiento es RELATIVO a donde estaba al empezar, que es (ix+8)
	ld (ix+000h),a		;5a37
	inc de			;5a3a
	ld a,(de)			;5a3b
	add a,(ix+009h)		;5a3c
	ld (ix+001h),a		;5a3f
	ret			;5a42
L_5A43:
	ld a,002h		;5a43
	ld (ix+005h),a		;5a45   ; (ix+5) a 2: la secuencia queda plantada donde esta
	ret			;5a48

; ----------------------------------------------------------------------
; ===== La maquina persigue la pelota =====
; ----------------------------------------------------------------------
persigue_la_pelota:		; mueve al muneco hacia la altura de la pelota, a la velocidad que toque
	ld a,(0e114h)		;5a49   ; pasada la fase 3 ya no se persigue nada
	cp 003h		;5a4c
	ret nc			;5a4e
	ld a,(ix+004h)		;5a4f
	and 002h		;5a52   ; el bit 1 dice de que lado se juega
	ld a,(ix+001h)		;5a54
	jr z,L_5A5A		;5a57
	ld b,c			;5a59   ; y por ese lado se le suma el margen que trae C
L_5A5A:
	add a,b			;5a5a
	ld b,a			;5a5b
	ld a,(0e102h)		;5a5c   ; (0xE102) es la altura de la pelota
	ld c,000h		;5a5f
	sub b			;5a61   ; la diferencia con la del muneco
	jr z,L_5A6B		;5a62
	ld c,001h		;5a64   ; C queda en 1 si hay que bajar
	jr nc,L_5A6B		;5a66
	inc c			;5a68   ; y en 2 si hay que subir
	neg		;5a69
L_5A6B:
	cp 002h		;5a6b   ; una diferencia menor que dos no merece moverse
	jr nc,L_5A71		;5a6d
	ld c,000h		;5a6f
L_5A71:
	ld a,c			;5a71
	and a			;5a72
	ret z			;5a73   ; y si no hay diferencia, quieto
	dec a			;5a74
	ld a,(ix+004h)		;5a75
	jr nz,L_5A93		;5a78
	and 002h		;5a7a
	jr z,L_5A7F		;5a7c
	ex de,hl			;5a7e
L_5A7F:
	rrc (hl)		;5a7f   ; LA VELOCIDAD: se rota un patron de bits y solo se mueve cuando sale un uno
	ret nc			;5a81   ; este cuadro le tocaba estarse quieto
	ld a,(ix+001h)		;5a82
	cp 0a2h		;5a85   ; y por abajo no pasa de 0xA2
	jr nc,L_5A8B		;5a87
	inc a			;5a89   ; dos pixeles por paso
	inc a			;5a8a
L_5A8B:
	ld (ix+001h),a		;5a8b
	xor a			;5a8e
	ld (ix+00dh),a		;5a8f   ; (ix+0x0D) es hacia donde mira
	ret			;5a92
L_5A93:
	and 002h		;5a93
	jr nz,L_5A98		;5a95
	ex de,hl			;5a97
L_5A98:
	rrc (hl)		;5a98   ; la otra direccion, con el mismo patron de velocidad
	ret nc			;5a9a
	ld a,(ix+001h)		;5a9b
	cp 05bh		;5a9e   ; y por arriba el tope es 0x5B
	jr c,L_5AA4		;5aa0
	dec a			;5aa2
	dec a			;5aa3
L_5AA4:
	ld (ix+001h),a		;5aa4
	ld a,001h		;5aa7
	ld (ix+00dh),a		;5aa9
	ret			;5aac
L_5AAD:
	ld a,(ix+001h)		;5aad   ; la altura del muneco
	jr z,L_5ABC		;5ab0
	ld d,a			;5ab2
	sub 00eh		;5ab3   ; catorce por delante
	ld b,a			;5ab5
	add a,014h		;5ab6   ; y veinte mas alla: la horquilla en la que llega a la pelota
	ld c,a			;5ab8
	ld e,a			;5ab9
	jr L_5AC4		;5aba
L_5ABC:
	ld e,a			;5abc   ; la altura del muneco
	add a,00eh		;5abd   ; catorce mas
	ld c,a			;5abf   ; el borde de arriba de la horquilla
	sub 014h		;5ac0   ; y veinte menos
	ld b,a			;5ac2   ; el de abajo
	ld d,a			;5ac3   ; guardado tambien
L_5AC4:
	ld a,(ix+011h)		;5ac4   ; (ix+0x11) son los golpes ya dados
	cp 002h		;5ac7   ; con dos golpes o mas, no hay golpe especial
	jr nc,L_5B25		;5ac9   ; y se sale
	ld a,(hl)			;5acb   ; el mando
	cp 001h		;5acc   ; solo con esa direccion vale
	jr nz,L_5B25		;5ace   ; y si no, fuera
	ld a,(0e114h)		;5ad0   ; la fase del intercambio
	dec a			;5ad3   ; en la 1 no vale
	jr z,L_5B25		;5ad4   ; y se sale
	ld a,(0e14ch)		;5ad6   ; (0xE14C), la falta
	and a			;5ad9   ; con falta pendiente
	jr nz,L_5B25		;5ada   ; tampoco
	ld a,(0e102h)		;5adc   ; la altura de la pelota
	cp b			;5adf   ; por debajo de la horquilla
	jr c,L_5B25		;5ae0   ; no llega
	cp c			;5ae2   ; y por encima
	jr nc,L_5B25		;5ae3   ; tampoco
	cp d			;5ae5   ; la horquilla estrecha, la del golpe bueno
	jr c,L_5AF5		;5ae6   ; por debajo, golpe normal
	cp e			;5ae8   ; y por encima
	jr nc,L_5AF5		;5ae9   ; tambien
	ld a,(0e147h)		;5aeb   ; (0xE147), el roce de red
	and a			;5aee   ; sin el
	jr z,L_5AF5		;5aef   ; no hay golpe especial
	ld a,001h		;5af1   ; uno: golpe especial
	jr L_5AF6		;5af3   ; y se guarda
L_5AF5:
	xor a			;5af5   ; cero: normal
L_5AF6:
	ld (0e14fh),a		;5af6   ; en (0xE14F)
	ld a,(ix+000h)		;5af9   ; la posicion del muneco
	sub 004h		;5afc   ; cuatro menos
	ld e,a			;5afe   ; guardada
	add a,008h		;5aff
	ld d,a			;5b01
	ld a,(0e100h)		;5b02
	cp e			;5b05
	jr c,L_5B25		;5b06
	cp d			;5b08
	jr nc,L_5B25		;5b09
	ld b,00ah		;5b0b
	ld a,(0e147h)		;5b0d
	and a			;5b10
	jr nz,L_5B15		;5b11
	ld b,015h		;5b13
L_5B15:
	ld a,(0e104h)		;5b15
	sub (ix+002h)		;5b18
	jr nc,L_5B1F		;5b1b
	neg		;5b1d
L_5B1F:
	cp b			;5b1f
	jr nc,L_5B25		;5b20
	or 001h		;5b22
	ret			;5b24
L_5B25:
	xor a			;5b25
	ld (0e14fh),a		;5b26
	and 000h		;5b29
	ret			;5b2b
mueve_al_lejano:		; lo mismo que con el cercano, sobre el otro bloque de estado
	ld ix,0e180h		;5b2c
	ld hl,0e049h		;5b30
	ld b,001h		;5b33
	call L_59D4		;5b35
	ld a,(0e185h)		;5b38   ; (0xE185) distinto de cero: esta en mitad de un golpe
	and a			;5b3b
	ld hl,05f63h		;5b3c
	jp nz,L_59E0		;5b3f
	ld b,0f9h		;5b42   ; 0xF9 es su patron de velocidad: se mueve en seis de cada ocho cuadros
	ld c,007h		;5b44
	ld de,0e18ah		;5b46
	ld hl,0e18bh		;5b49
	call persigue_la_pelota		;5b4c   ; y persigue la pelota con ese paso
	ld hl,0e048h		;5b4f
	ld a,(0e002h)		;5b52
	bit 5,a		;5b55   ; con dos jugadores manda la persona, no la maquina
	jr nz,L_5B5C		;5b57
	call decide_el_golpe		;5b59
L_5B5C:
	ld hl,0e048h		;5b5c   ; los flancos del segundo jugador
	ld de,0e049h		;5b5f   ; y su mando crudo
	call L_594B		;5b62   ; se ajusta lo que se acaba de pulsar
	ld a,(0e002h)		;5b65   ; el modo
	bit 5,a		;5b68   ; el bit 5, dos jugadores
	jp z,L_5B70		;5b6a   ; con uno, la maquina decide hacia donde mira
	ret			;5b6d   ; y con dos, manda la persona
sin_mando:		; devuelve cero: cuando juega la maquina no hay mando que leer
	xor a			;5b6e   ; cero: la maquina no tiene mando que leer
	ret			;5b6f
L_5B70:
	ld a,(0e10dh)		;5b70   ; (0xE10D): hacia donde va la pelota
	ld (0e18dh),a		;5b73
	ld de,0e18eh		;5b76
	ld a,(0e18dh)		;5b79
	and a			;5b7c
	ld a,000h		;5b7d   ; y de ahi sale hacia que lado se vuelve el muneco
	jr nz,L_5B82		;5b7f
	inc a			;5b81
L_5B82:
	ld (de),a			;5b82
	jp L_59B0		;5b83
L_5B86:
	ret			;5b86

; ----------------------------------------------------------------------
; ===== CUANDO GOLPEA LA MAQUINA =====
; ----------------------------------------------------------------------
decide_el_golpe:		; la maquina golpea si la pelota le llega a la altura justa
	ld a,(0e147h)		;5b87   ; tras un roce de red, no
	and a			;5b8a
	jr nz,L_5BB2		;5b8b
	ld a,(0e140h)		;5b8d   ; ni si le toca al otro lado
	and a			;5b90
	ret z			;5b91
	ld a,(0e114h)		;5b92   ; ni fuera de la fase 0
	and a			;5b95
	ret nz			;5b96
	ld a,(0e10eh)		;5b97   ; (0xE10E): tiene que estar CAYENDO
	and a			;5b9a
	ret z			;5b9b
	ld a,(0e104h)		;5b9c   ; la altura de la pelota
	cp 03dh		;5b9f   ; y la ventana es estrecha: solo entre 0x3D y 0x3F
	ret c			;5ba1
	cp 040h		;5ba2
	ret nc			;5ba4
	push hl			;5ba5
	call L_5C45		;5ba6   ; aqui decide de que lado la manda
	pop hl			;5ba9
	ld a,004h		;5baa   ; el bit 2 del mando fingido
	jr c,L_5BB0		;5bac
	ld a,008h		;5bae   ; o el 3
L_5BB0:
	ld (hl),a			;5bb0   ; y eso es lo que el resto del juego lee como si fuera un mando
	ret			;5bb1
L_5BB2:
	ld a,(0e047h)		;5bb2   ; (0xE047) es el nivel
	cp 002h		;5bb5   ; del 2 para arriba, la maquina juega de otra manera
	jr nc,L_5BE4		;5bb7
	ld hl,05c58h		;5bb9   ; las tablas que gobiernan su juego, por nivel
	push af			;5bbc
	add a,a			;5bbd
	call suma_a_hl		;5bbe
	ld b,(hl)			;5bc1
	inc hl			;5bc2
	ld c,(hl)			;5bc3
	pop af			;5bc4
	ld hl,05c5ch		;5bc5
	call suma_a_hl		;5bc8
	ld a,(0e145h)		;5bcb   ; (0xE145) son los puntos jugados: pasado el umbral, aprieta
	cp (hl)			;5bce
	jr c,L_5BE4		;5bcf
	ld a,(0e110h)		;5bd1
	and a			;5bd4
	jr nz,L_5BE4		;5bd5
	ld a,(0e151h)		;5bd7
	cp b			;5bda
	jr c,L_5BE0		;5bdb
	cp c			;5bdd
	jr c,L_5BE4		;5bde
L_5BE0:
	ld a,0a0h		;5be0
	jr L_5C09		;5be2
L_5BE4:
	ld a,(0e047h)		;5be4   ; el nivel
	ld b,a			;5be7   ; guardado
	ld a,(0e150h)		;5be8   ; el alcance del ultimo golpe
	cp 01dh		;5beb   ; 0x1D es el golpe corto
	jr nz,L_5C01		;5bed   ; y si no lo fue, se sigue
	ld a,b			;5bef   ; el nivel
	add a,005h		;5bf0   ; mas cinco: la maquina responde mejor a los cortos
	ld b,a			;5bf2   ; guardado
	ld a,(0e047h)		;5bf3   ; el nivel otra vez
	and a			;5bf6   ; cero es el mas facil
	jr nz,L_5C01		;5bf7   ; y en los demas, adelante
	ld hl,0e1abh		;5bf9   ; (0xE1AB): el pestillo del nivel facil
	ld a,(hl)			;5bfc   ; leido
	and a			;5bfd   ; a cero
	jr nz,L_5BE0		;5bfe   ; y si ya estaba, se falla a proposito
	inc (hl)			;5c00   ; y si no, se echa: en el nivel facil solo acierta una de cada dos
L_5C01:
	ld a,b			;5c01   ; el indice que ha quedado
	ld hl,05c63h		;5c02   ; la tabla de respuestas
	call suma_a_hl		;5c05   ; mas el indice
	ld a,(hl)			;5c08   ; y el valor que sale
L_5C09:
	ld hl,0e100h		;5c09   ; la coordenada larga de la pelota
	cp (hl)			;5c0c   ; si aun no ha llegado
	ret nc			;5c0d   ; no se hace nada
	add a,008h		;5c0e   ; ocho mas alla
	cp (hl)			;5c10   ; si ya ha pasado
	ret c			;5c11   ; tampoco
	ld a,(0e114h)		;5c12   ; la fase del intercambio
	cp 003h		;5c15   ; de la 3 en adelante
	ret nc			;5c17   ; no
	ld a,(0e047h)		;5c18   ; el nivel
	ld hl,05c5eh		;5c1b   ; la tabla de umbrales por nivel
	call suma_a_hl		;5c1e   ; mas el nivel
	ld a,(0e145h)		;5c21   ; los puntos ya jugados
	cp (hl)			;5c24   ; contra el umbral de este nivel
	jr c,L_5C37		;5c25   ; y por debajo, la maquina juega flojo
	ld hl,0e1a9h		;5c27   ; (0xE1A9): el patron de aciertos
	rrc (hl)		;5c2a   ; se rota un bit
	jr nc,L_5C37		;5c2c   ; y si sale cero, este golpe lo falla a proposito
	ld b,001h		;5c2e   ; uno: el golpe bueno
	ld a,(0e104h)		;5c30   ; la altura de la pelota
	cp 049h		;5c33   ; por encima de 0x49
	jr nc,L_5C40		;5c35   ; se queda con ese
L_5C37:
	call L_5C45		;5c37   ; y si no, decide por donde la manda
	ld b,008h		;5c3a   ; ocho
	jr nc,L_5C40		;5c3c   ; segun el lado
	ld b,004h		;5c3e   ; o cuatro
L_5C40:
	ld a,b			;5c40
	ld (0e048h),a		;5c41
	ret			;5c44
L_5C45:
	ld hl,0e1a8h		;5c45
	sla (hl)		;5c48
	ld b,007h		;5c4a
L_5C4C:
	dec hl			;5c4c   ; al byte anterior
	rl (hl)		;5c4d   ; un bit a la izquierda: el patron de aciertos va rotando
	djnz L_5C4C		;5c4f   ; los bytes que haga falta
	ret nc			;5c51   ; sin acarreo, no toca
	ld hl,0e1a8h		;5c52   ; (0xE1A8), las banderas del golpe
	set 0,(hl)		;5c55   ; y se enciende el bit 0
	ret			;5c57   ; hecho

; ----------------------------------------------------------------------
; DATOS datos_5c58: 4 bytes que carga 0x5BB9
;   0x5c58..0x5c5c  (4 bytes)
DATA_datos_5c58:
	defb 01bh,022h,01ah,023h	; 5c58

; ----------------------------------------------------------------------
; DATOS datos_5c5c: 2 bytes que carga 0x5BC5
;   0x5c5c..0x5c5e  (2 bytes)
DATA_datos_5c5c:
	defb 00ah,010h	; 5c5c

; ----------------------------------------------------------------------
; DATOS datos_5c5e: 5 bytes que cargan 0x5C1B y 0x5D18
;   0x5c5e..0x5c63  (5 bytes)
DATA_datos_5c5e:
	defb 010h,00ch,009h,006h,003h	; 5c5e

; ----------------------------------------------------------------------
; DATOS datos_5c63: 10 bytes que carga 0x5C02
;   0x5c63..0x5c6d  (10 bytes)
DATA_datos_5c63:
	defb 097h,096h,095h,093h,091h,092h,08fh,08ch,08ah,088h	; 5c63  ..........

; ======================================================================
; CODIGO 0x5c6d..0x5d37  (202 bytes)
; ======================================================================


finge_el_mando:		; el mando que la maquina se inventa para moverse en el menu
	ld a,(0e1aah)		;5c6d   ; (0xE1AA) es la pausa entre movimientos
	and a			;5c70
	jr z,L_5C82		;5c71
	push hl			;5c73
	ld hl,0e004h		;5c74
	dec (hl)			;5c77   ; mientras dure, quieta
	pop hl			;5c78
	ret nz			;5c79
	xor a			;5c7a
	ld (0e1aah),a		;5c7b
	ld a,001h		;5c7e
	ld (de),a			;5c80
	ret			;5c81
L_5C82:
	ld a,(0e003h)		;5c82
	ld b,008h		;5c85
	bit 4,a		;5c87   ; el bit 4 del reloj decide hacia que lado
	jr nz,L_5C8D		;5c89
	ld b,004h		;5c8b
L_5C8D:
	ld a,b			;5c8d
	ld (de),a			;5c8e
	ld a,(0e003h)		;5c8f
	and 00fh		;5c92   ; y cada dieciseis cuadros
	ret nz			;5c94
	ld a,040h		;5c95   ; se para 0x40 cuadros
	ld (0e004h),a		;5c97
	ld (0e1aah),a		;5c9a
	ret			;5c9d

; ----------------------------------------------------------------------
; ===== LAS SEIS ZONAS: adonde manda la maquina la pelota =====
; ----------------------------------------------------------------------
elige_la_trayectoria:		; segun por que zona le llega la pelota, saca adonde la devuelve
	ld b,000h		;5c9e
	ld a,(0e102h)		;5ca0   ; por donde le llega, a lo ancho
	cp 040h		;5ca3   ; cinco cortes -0x40, 0x72, 0x80, 0x8C y 0x98- que dan SEIS zonas
	jr c,L_5CBC		;5ca5
	inc b			;5ca7
	cp 072h		;5ca8
	jr c,L_5CBC		;5caa
	inc b			;5cac
	cp 080h		;5cad
	jr c,L_5CBC		;5caf
	inc b			;5cb1
	cp 08ch		;5cb2
	jr c,L_5CBC		;5cb4
	inc b			;5cb6
	cp 098h		;5cb7
	jr c,L_5CBC		;5cb9
	inc b			;5cbb
L_5CBC:
	ld a,(0e047h)		;5cbc   ; y el nivel
	ld c,a			;5cbf
	add a,a			;5cc0   ; multiplicado por doce: seis entradas de palabra por nivel
	add a,c			;5cc1
	add a,a			;5cc2
	add a,a			;5cc3
	ld hl,05d37h		;5cc4   ; la tabla de treinta
	call suma_a_hl		;5cc7
	ld a,b			;5cca
	add a,a			;5ccb   ; mas la zona doblada
	call suma_a_hl		;5ccc
	ld a,(hl)			;5ccf
	ld e,a			;5cd0
	inc hl			;5cd1
	ld a,(hl)			;5cd2
	ld d,a			;5cd3
	ld a,(0e002h)		;5cd4
	bit 6,a		;5cd7
	ld a,001h		;5cd9
	jr z,L_5CE5		;5cdb
	ld a,(0e003h)		;5cdd
	rra			;5ce0
	rra			;5ce1
	rra			;5ce2
	and 003h		;5ce3
L_5CE5:
	ex de,hl			;5ce5   ; el puntero a la tabla
	call suma_a_hl		;5ce6   ; mas el indice
	ld a,(hl)			;5ce9   ; el valor
	ld (0e151h),a		;5cea   ; a (0xE151), el efecto
	ld a,(0e003h)		;5ced   ; el reloj
	bit 6,a		;5cf0   ; el bit 6, que cambia cada 64 cuadros
	jr nz,L_5CFB		;5cf2   ; y con el puesto, se mira la red
	ld a,(0e150h)		;5cf4   ; el alcance del ultimo golpe
	cp 01dh		;5cf7   ; el golpe corto
	jr z,L_5D24		;5cf9   ; y entonces la maquina responde de otra manera
L_5CFB:
	ld a,(0e147h)		;5cfb   ; el roce de red
	and a			;5cfe   ; a cero
	jr z,L_5D2E		;5cff   ; no hay golpe especial
	ld a,(0e1a0h)		;5d01
	sub b			;5d04
	jr nc,L_5D09		;5d05
	neg		;5d07
L_5D09:
	cp 004h		;5d09   ; de la fase 4 en adelante
	jr nc,L_5D24		;5d0b   ; se mira el roce de red
	cp 002h		;5d0d   ; y por debajo de la 2
	jr c,L_5D2E		;5d0f   ; no hay golpe especial
	ld a,(0e047h)		;5d11   ; el nivel
	ld c,a			;5d14   ; guardado
	ld a,004h		;5d15   ; cuatro
	sub c			;5d17   ; menos el nivel: cuanto mas alto, MENOS puntos hacen falta
	ld hl,05c5eh		;5d18   ; la tabla de umbrales
	call suma_a_hl		;5d1b   ; mas el indice
	ld a,(0e145h)		;5d1e   ; los puntos jugados
	cp (hl)			;5d21   ; contra el umbral
	jr c,L_5D2E		;5d22   ; y por debajo, nada
L_5D24:
	ld a,(0e147h)		;5d24   ; el roce de red
	and a			;5d27   ; a cero
	jr z,L_5D2E		;5d28   ; no hay golpe especial
	ld a,001h		;5d2a   ; uno: si lo hay
	jr L_5D2F		;5d2c   ; y se guarda
L_5D2E:
	xor a			;5d2e   ; cero
L_5D2F:
	ld (0e14fh),a		;5d2f   ; en (0xE14F)
	ld a,b			;5d32   ; el fotograma elegido
	ld (0e1a0h),a		;5d33   ; a (0xE1A0)
	ret			;5d36   ; hecho

; ----------------------------------------------------------------------
; DATOS tabla_de_trayectorias: 30 entradas -5 niveles por 6 zonas-, desde
;   0x5D73 hasta 0x5DE7. La lee 0x5CC4
;   0x5d37..0x5d73  (60 bytes)
DATA_tabla_de_trayectorias:
	defw 05d73h,05d77h,05d7bh,05d7fh,05d83h,05d87h,05d8bh,05d8fh	; 5d37
	defw 05d93h,05d97h,05d9bh,05d9fh,05da3h,05da7h,05dabh,05dafh	; 5d47
	defw 05db3h,05db7h,05dbbh,05dbfh,05dc3h,05dc7h,05dcbh,05dcfh	; 5d57
	defw 05dd3h,05dd7h,05ddbh,05ddfh,05de3h,05de7h	; 5d67

; ----------------------------------------------------------------------
; DATOS trayectorias: 30 registros de cuatro bytes, todos entre 0x18 y 0x24:
;   adonde apunta la maquina desde cada zona y en cada nivel
;   0x5d73..0x5deb  (120 bytes)
DATA_trayectorias:
	defb 01eh,01ch,01bh,01fh	; 5d73
	defb 01eh,01dh,01bh,01fh	; 5d77
	defb 01eh,01fh,01dh,01bh	; 5d7b
	defb 01eh,01fh,01dh,021h	; 5d7f
	defb 01eh,01fh,021h,01dh	; 5d83
	defb 01eh,020h,021h,01dh	; 5d87
	defb 01eh,01ch,01ah,01fh	; 5d8b
	defb 01eh,01ch,01ah,01fh	; 5d8f
	defb 01eh,01fh,01dh,01ah	; 5d93
	defb 01eh,01dh,01fh,022h	; 5d97
	defb 01eh,01fh,022h,01dh	; 5d9b
	defb 01eh,01fh,022h,01dh	; 5d9f
	defb 019h,01ch,01bh,01fh	; 5da3
	defb 01dh,01ch,01ah,020h	; 5da7
	defb 01ch,01fh,01bh,019h	; 5dab
	defb 020h,01dh,021h,023h	; 5daf
	defb 01fh,020h,021h,01ch	; 5db3
	defb 023h,020h,021h,01dh	; 5db7
	defb 01bh,01eh,019h,01dh	; 5dbb
	defb 01dh,01fh,01ch,01ah	; 5dbf
	defb 01ah,01fh,018h,01ch	; 5dc3
	defb 022h,01dh,023h,020h	; 5dc7
	defb 01fh,01dh,020h,022h	; 5dcb
	defb 021h,01eh,023h,01fh	; 5dcf
	defb 01bh,01eh,01ah,018h	; 5dd3
	defb 01ch,01ah,019h,020h	; 5dd7
	defb 01ch,019h,01fh,021h	; 5ddb
	defb 020h,023h,01dh,01bh	; 5ddf
	defb 020h,022h,023h,01dh	; 5de3
	defb 021h,01eh,022h,024h	; 5de7

; ======================================================================
; CODIGO 0x5deb..0x5ec7  (220 bytes)
; ======================================================================


L_5DEB:
	ld de,0e086h		;5deb   ; los colores del jugador cercano
	ld hl,05ec7h		;5dee   ; su tabla
	ld b,005h		;5df1   ; cinco sprites
	call L_5DFE		;5df3   ; repartidos de cuatro en cuatro
	ld de,0e0a6h		;5df6   ; y ahora el lejano
	ld hl,05ecch		;5df9   ; su tabla
	ld b,003h		;5dfc   ; tres sprites, que se dibuja con menos
L_5DFE:
	ld a,(hl)			;5dfe   ; el color de este sprite
	ld (de),a			;5dff   ; a su sitio
	inc de			;5e00   ; y se salta
	inc de			;5e01   ; los otros
	inc de			;5e02   ; tres bytes
	inc de			;5e03   ; del sprite
	inc hl			;5e04   ; al color siguiente
	djnz L_5DFE		;5e05   ; tantos como diga B
	ret			;5e07   ; hecho
L_5E08:
	ld hl,0e162h		;5e08   ; el bloque del jugador cercano
	ld b,001h		;5e0b   ; uno
	ld a,(0e10ch)		;5e0d   ; de quien es el turno
	and a			;5e10   ; a cero
	jr z,L_5E14		;5e11
	inc b			;5e13
L_5E14:
	call L_5E22		;5e14
	ld a,(0e163h)		;5e17
	ld de,0e084h		;5e1a
	ld hl,05ff7h		;5e1d
	jr L_5E68		;5e20
L_5E22:
	ld a,(0e114h)		;5e22
	cp b			;5e25
	ld a,03ah		;5e26
	jr nz,L_5E2D		;5e28
	ld a,(0e104h)		;5e2a
L_5E2D:
	cp 02ch		;5e2d
	jr c,L_5E32		;5e2f
	ld (hl),a			;5e31
L_5E32:
	dec hl			;5e32   ; el byte anterior
	ld b,(hl)			;5e33   ; la coordenada, a B
	dec hl			;5e34   ; y el de mas atras
	ld c,(hl)			;5e35   ; la otra, a C
	call L_5E3F		;5e36   ; que se pasan al reves
	inc hl			;5e39   ; dos bytes
	inc hl			;5e3a   ; adelante
	ld a,(hl)			;5e3b   ; la altura
	jp proyecta		;5e3c   ; y se proyecta a fila y columna
L_5E3F:
	ld a,080h		;5e3f   ; 0x80, el centro
	sub b			;5e41   ; menos la coordenada
	jr nc,L_5E4A		;5e42   ; sin prestamo, ya esta
	neg		;5e44   ; y con el, se le da la vuelta al signo
	add a,080h		;5e46
	jr L_5E4E		;5e48
L_5E4A:
	ld b,a			;5e4a
	ld a,080h		;5e4b
	sub b			;5e4d
L_5E4E:
	ld b,a			;5e4e
	ret			;5e4f
L_5E50:
	ld hl,0e182h		;5e50   ; el bloque del jugador lejano
	ld b,001h		;5e53   ; uno
	ld a,(0e10ch)		;5e55   ; de quien es el turno
	and a			;5e58   ; a cero
	jr nz,L_5E5C		;5e59   ; no se corrige
	inc b			;5e5b   ; y si no, uno mas: al de enfrente le toca al reves
L_5E5C:
	call L_5E22		;5e5c   ; se coloca su sombra
	ld a,(0e183h)		;5e5f   ; su fotograma
	ld de,0e0a4h		;5e62
	ld hl,0601fh		;5e65
L_5E68:
	push de			;5e68   ; el destino, que hace falta luego
	add a,a			;5e69   ; el indice doblado, que la tabla es de palabras
	call suma_a_hl		;5e6a   ; sumado a la tabla
	ld e,(hl)			;5e6d   ; la entrada
	inc hl			;5e6e   ; el byte siguiente
	ld d,(hl)			;5e6f   ; y su byte alto
	ex de,hl			;5e70   ; a HL: el fotograma
	pop de			;5e71   ; se recupera el destino
	ld a,b			;5e72   ; la referencia
	ld b,005h		;5e73   ; cinco sprites como mucho
L_5E75:
	push bc			;5e75   ; la cuenta de sprites, que el bucle la pisa
	ld b,a			;5e76   ; y B pasa a llevar la coordenada de referencia
	ld a,(hl)			;5e77   ; el primer byte del fotograma
	cp 081h		;5e78   ; el 0x81 dice que este fotograma lleva menos sprites
	jr z,L_5E91		;5e7a   ; y entonces se corta
	ld a,(hl)			;5e7c   ; el desplazamiento vertical
	add a,c			;5e7d   ; sumado a donde esta el muneco
	ld (de),a			;5e7e   ; a la Y del sprite
	inc hl			;5e7f   ; al byte siguiente del fotograma
	inc de			;5e80   ; y al del sprite
	ld a,(hl)			;5e81   ; el desplazamiento horizontal
	add a,b			;5e82   ; sumado
	ld (de),a			;5e83   ; a la X del sprite
	inc hl			;5e84   ; al siguiente
	inc de			;5e85   ; y al siguiente
	inc de			;5e86   ; saltandose el color, que ya esta puesto
	ld a,(hl)			;5e87   ; el numero de patron
	ld (de),a			;5e88   ; a su sitio
	inc hl			;5e89   ; al byte siguiente del fotograma
	inc de			;5e8a   ; y al del sprite siguiente
	ld a,b			;5e8b   ; la referencia, que hace falta en la vuelta siguiente
	pop bc			;5e8c   ; y se recupera la cuenta
	djnz L_5E75		;5e8d   ; tantos sprites como diga
	jr L_5E9B		;5e8f   ; y al puntero de los patrones
L_5E91:
	pop bc			;5e91   ; se recupera la cuenta
L_5E92:
	ld a,0e0h		;5e92   ; 0xE0: fuera de la pantalla
	ld (de),a			;5e94
	inc de			;5e95
	inc de			;5e96
	inc de			;5e97
	inc de			;5e98
	djnz L_5E92		;5e99
L_5E9B:
	inc hl			;5e9b   ; el puntero que va detras de los datos de sprite
	ld e,(hl)			;5e9c   ; su byte bajo
	inc hl			;5e9d   ; el siguiente
	ld d,(hl)			;5e9e   ; y su byte alto
	ex de,hl			;5e9f   ; a HL: ahi esta el bloque comprimido
	ld e,(hl)			;5ea0   ; su primer word
	inc hl			;5ea1   ; el byte siguiente
	ld d,(hl)			;5ea2   ; y su byte alto
	ex de,hl			;5ea3   ; a HL: el destino en la VRAM
	inc de			;5ea4   ; y DE queda en el primer mandato
	call prepara_escritura		;5ea5   ; se abre el puerto de escritura
L_5EA8:
	ld a,(de)			;5ea8   ; el mandato
	and a			;5ea9   ; a cero cierra el bloque
	ret z			;5eaa
	inc de			;5eab
	jp p,L_5EBC		;5eac
	and 07fh		;5eaf
	ld b,a			;5eb1
L_5EB2:
	ld a,(de)			;5eb2   ; un byte del literal
	inc de			;5eb3   ; y al siguiente
	exx			;5eb4   ; al juego alterno, donde esta el puerto
	out (c),a		;5eb5   ; al VDP, sin pasar por la BIOS
	exx			;5eb7   ; y de vuelta
	djnz L_5EB2		;5eb8   ; tantos como diga la cuenta
	jr L_5EA8		;5eba   ; y a por el mandato siguiente
L_5EBC:
	ld b,a			;5ebc   ; la cuenta de la repeticion
	ld a,(de)			;5ebd
	inc de			;5ebe
L_5EBF:
	exx			;5ebf
	out (c),a		;5ec0
	exx			;5ec2
	djnz L_5EBF		;5ec3
	jr L_5EA8		;5ec5

; ----------------------------------------------------------------------
; DATOS colores_del_jugador_cercano: 5 bytes que 0x5DEB reparte de cuatro en
;   cuatro desde 0xE086: el color de cada uno de sus cinco sprites
;   0x5ec7..0x5ecc  (5 bytes)
DATA_colores_del_jugador_cercano:
	defb 000h	; 5ec7
	defb 004h	; 5ec8
	defb 008h	; 5ec9
	defb 00ch	; 5eca
	defb 010h	; 5ecb

; ----------------------------------------------------------------------
; DATOS colores_del_jugador_lejano: 3 bytes que 0x5DF6 reparte desde 0xE0A6
;   0x5ecc..0x5ecf  (3 bytes)
DATA_colores_del_jugador_lejano:
	defb 014h	; 5ecc
	defb 018h	; 5ecd
	defb 01ch	; 5ece

; ----------------------------------------------------------------------
; DATOS tabla_de_trayectorias_cercano: 4 entradas; la indexa 0x5A09 con (ix+4)
;   enmascarado a 3 bits. La primera apunta a 0x5ED7, justo detras
;   0x5ecf..0x5ed7  (8 bytes)
DATA_tabla_de_trayectorias_cercano:
	defw 05ed7h,05ef8h,05f19h,05f3eh	; 5ecf  -> DATA_trayectorias_del_cercano 0x5ef8 0x5f19 0x5f3e

; ----------------------------------------------------------------------
; DATOS trayectorias_del_cercano: cuatro secuencias de desplazamientos con
;   signo, cada una cerrada por el 0xA0 que busca el `cp 0a0h` de 0x5A1E;
;   (ix+7) es el paso dentro de la secuencia
;   0x5ed7..0x5f63  (140 bytes)
DATA_trayectorias_del_cercano:
	defb 000h,000h,002h,003h,004h,005h,0a0h,005h,005h,007h,006h,00bh,005h,0a0h,00dh,004h	; 5ed7  ................
	defb 00fh,000h,0a0h,00fh,0ffh,00fh,0fdh,00fh,0fbh,0a0h,00eh,0f9h,00ch,0f8h,00ah,0f7h	; 5ee7  ................
	defb 0aah,000h,000h,002h,0fdh,004h,0fbh,0a0h,005h,0fbh,007h,0fah,00bh,0fbh,0a0h,00dh	; 5ef7  ................
	defb 0fch,00fh,000h,0a0h,00fh,001h,00fh,003h,00fh,005h,0a0h,00eh,007h,00ch,008h,00ah	; 5f07  ................
	defb 009h,0aah,000h,000h,002h,005h,002h,005h,002h,005h,003h,004h,0a0h,004h,003h,005h	; 5f17  ................
	defb 002h,007h,001h,0a0h,008h,001h,00ch,001h,0a0h,00dh,000h,00eh,0ffh,00fh,0feh,0a0h	; 5f27  ................
	defb 00fh,0fdh,00fh,0fch,00fh,0fbh,0aah,000h,000h,002h,0fbh,002h,0fbh,002h,0fbh,003h	; 5f37  ................
	defb 0fch,0a0h,004h,0fdh,005h,0feh,007h,0ffh,0a0h,008h,0ffh,00ch,0ffh,0a0h,00dh,000h	; 5f47  ................
	defb 00eh,001h,00fh,002h,0a0h,00fh,003h,00fh,004h,00fh,005h,0aah	; 5f57  ............

; ----------------------------------------------------------------------
; DATOS tabla_de_trayectorias_lejano: las mismas 4 entradas para el otro
;   jugador; la primera apunta a 0x5F6B
;   0x5f63..0x5f6b  (8 bytes)
DATA_tabla_de_trayectorias_lejano:
	defw 05f6bh,05f8ch,05fadh,05fd2h	; 5f63  -> DATA_trayectorias_del_lejano 0x5f8c 0x5fad 0x5fd2

; ----------------------------------------------------------------------
; DATOS trayectorias_del_lejano: las cuatro secuencias del otro jugador, con
;   los signos cambiados
;   0x5f6b..0x5ff7  (140 bytes)
DATA_trayectorias_del_lejano:
	defb 000h,000h,0feh,0fdh,0fch,0fbh,0a0h,0fbh,0fbh,0f9h,0fah,0f5h,0fbh,0a0h,0f3h,0fch	; 5f6b  ................
	defb 0f1h,000h,0a0h,0f1h,001h,0f1h,003h,0f1h,005h,0a0h,0f2h,007h,0f4h,008h,0f6h,009h	; 5f7b  ................
	defb 0aah,000h,000h,0feh,003h,0fch,005h,0a0h,0fbh,005h,0f9h,006h,0f5h,005h,0a0h,0f3h	; 5f8b  ................
	defb 004h,0f1h,000h,0a0h,0f1h,0ffh,0f1h,0fdh,0f1h,0fbh,0a0h,0f2h,0f9h,0f4h,0f8h,0f6h	; 5f9b  ................
	defb 0f7h,0aah,000h,000h,0feh,0fbh,0feh,0fbh,0feh,0fbh,0fdh,0fch,0a0h,0fch,0fdh,0fbh	; 5fab  ................
	defb 0feh,0f9h,0ffh,0a0h,0f8h,0ffh,0f4h,0ffh,0a0h,0f3h,000h,0f2h,001h,0f1h,002h,0a0h	; 5fbb  ................
	defb 0f1h,003h,0f1h,004h,0f1h,005h,0aah,000h,000h,0feh,005h,0feh,005h,0feh,005h,0fdh	; 5fcb  ................
	defb 004h,0a0h,0fch,003h,0fbh,002h,0f9h,001h,0a0h,0f8h,001h,0f4h,001h,0a0h,0f3h,000h	; 5fdb  ................
	defb 0f2h,0ffh,0f1h,0feh,0a0h,0f1h,0fdh,0f1h,0fch,0f1h,0fbh,0aah	; 5feb  ............

; ----------------------------------------------------------------------
; DATOS tabla_de_fotogramas_cercano: 20 entradas, indexada por (0xE163) desde
;   0x5E1D. La primera apunta a 0x6047, justo detras de las DOS tablas
;   0x5ff7..0x601f  (40 bytes)
DATA_tabla_de_fotogramas_cercano:
	defw 06047h,06059h,06068h,06074h,06080h,0608ch,06098h,060a4h	; 5ff7
	defw 060b0h,060bch,060c8h,060dah,060e9h,060f5h,06101h,0610dh	; 6007
	defw 06119h,06125h,06131h,0613dh	; 6017

; ----------------------------------------------------------------------
; DATOS tabla_de_fotogramas_lejano: 20 entradas, indexada por (0xE183) desde
;   0x5E65
;   0x601f..0x6047  (40 bytes)
DATA_tabla_de_fotogramas_lejano:
	defw 06149h,06152h,0615bh,06167h,06170h,06179h,06182h,0618eh	; 601f
	defw 0619ah,061a3h,061ach,061b5h,061beh,061cah,061d3h,061dch	; 602f
	defw 061e5h,061f1h,061fdh,06206h	; 603f

; ----------------------------------------------------------------------
; DATOS fotogramas_del_cercano: 20 fotogramas de hasta CINCO sprites: [dy, dx,
;   patron] por sprite, el 0x81 que corta, y el puntero a sus patrones
;   comprimidos
;   0x6047..0x6149  (258 bytes)
DATA_fotogramas_del_cercano:
	defb 0fch,0f9h,00fh,0f9h,0fah,00ah,0f9h,00ah,00ah,009h,0f2h,00ah,009h,002h,00ah,081h	; 6047  ................
	defb 0a7h,073h,0fbh,0f7h,00fh,0efh,002h,00ah,0fah,0f2h,00ah,0ffh,002h,00ah,081h,003h	; 6057  .s..............
	defb 074h,0fbh,0fah,00fh,0fbh,0f3h,00ah,0f8h,003h,00ah,081h,059h,074h,0f9h,0fah,00fh	; 6067  t..........Yt...
	defb 0f2h,000h,00ah,0f5h,0f8h,00ah,081h,09bh,074h,0f9h,0fch,00fh,0f0h,0fch,00ah,000h	; 6077  ........t.......
	defb 0fbh,00ah,081h,0e5h,074h,0feh,0f9h,00fh,0fbh,0fah,00ah,004h,00ah,00ah,081h,0beh	; 6087  ....t...........
	defb 076h,0feh,0fah,00fh,0feh,0f7h,00ah,0ffh,007h,00ah,081h,0fah,076h,0feh,0fbh,00fh	; 6097  v...........v...
	defb 0fdh,0f3h,009h,0f6h,003h,009h,081h,035h,077h,0fch,0f8h,00fh,0f7h,0f2h,009h,0f1h	; 60a7  .......5w.......
	defb 002h,009h,081h,080h,077h,0fch,0fbh,00fh,0f3h,0f9h,009h,003h,0ffh,009h,081h,0cdh	; 60b7  ....w...........
	defb 077h,0fbh,0f6h,00fh,0f9h,0f6h,00ah,0f9h,0e6h,00ah,009h,0feh,00ah,009h,0eeh,00ah	; 60c7  w...............
	defb 081h,02fh,075h,0fbh,0f9h,00fh,0efh,0eeh,00ah,0fah,0feh,00ah,0ffh,0eeh,00ah,081h	; 60d7  ./u.............
	defb 08ah,075h,0fah,0f8h,00fh,0fbh,0fdh,00ah,0f8h,0edh,00ah,081h,0e1h,075h,0fah,0fah	; 60e7  .u...........u..
	defb 00fh,0f2h,0f0h,00ah,0f5h,0f8h,00ah,081h,025h,076h,0f8h,0fch,00fh,0f0h,0f4h,00ah	; 60f7  ........%v......
	defb 000h,0f5h,00ah,081h,070h,076h,0feh,0f6h,00fh,0fbh,0f6h,00ah,004h,0e6h,00ah,081h	; 6107  ....pv..........
	defb 007h,078h,0fdh,0f8h,00fh,0feh,0f9h,00ah,0ffh,0e9h,00ah,081h,045h,078h,0f9h,0f7h	; 6117  .x..........Ex..
	defb 00fh,0fdh,0fdh,009h,0f6h,0edh,009h,081h,081h,078h,0fch,0f7h,00fh,0f7h,0feh,009h	; 6127  .........x......
	defb 0f1h,0eeh,009h,081h,0c9h,078h,0fch,0fbh,00fh,0f3h,0f9h,009h,003h,0ffh,009h,081h	; 6137  .....x..........
	defb 018h,079h	; 6147

; ----------------------------------------------------------------------
; DATOS fotogramas_del_lejano: 20 fotogramas de dos o tres sprites, con el
;   mismo formato; el jugador del fondo se dibuja con menos
;   0x6149..0x620f  (198 bytes)
DATA_fotogramas_del_lejano:
	defb 0fch,0fbh,00fh,0fdh,0f6h,009h,081h,052h,079h,0fbh,0f9h,00fh,0fdh,0f3h,009h,081h	; 6149  .......Ry.......
	defb 089h,079h,0fah,0fah,00fh,0feh,0f2h,00ah,0ffh,002h,00ah,081h,0b8h,079h,0fbh,0f8h	; 6159  .y...........y..
	defb 00fh,0feh,0f4h,00ah,081h,0e1h,079h,0fah,0fah,00fh,0feh,0fah,00ah,081h,00bh,07ah	; 6169  ......y........z
	defb 0fch,0fch,00fh,0f6h,0f6h,009h,081h,022h,07bh,0fdh,0fbh,00fh,0f8h,0f4h,009h,001h	; 6179  ......."{.......
	defb 004h,009h,081h,058h,07bh,0fdh,0fdh,00fh,0fdh,0f4h,009h,0feh,004h,009h,081h,092h	; 6189  ...X{...........
	defb 07bh,0fch,0fdh,00fh,0fch,0f6h,009h,081h,0cah,07bh,0fdh,0fch,00fh,0fdh,0fah,009h	; 6199  {........{......
	defb 081h,0f7h,07bh,0fbh,0f9h,00fh,0fdh,0fdh,009h,081h,03ah,07ah,0f9h,0fch,00fh,0fdh	; 61a9  ..{.......:z....
	defb 0fdh,009h,081h,071h,07ah,0f8h,0fch,00fh,0feh,0feh,00ah,0ffh,0fbh,00ah,081h,09eh	; 61b9  ...qz...........
	defb 07ah,0fah,0fdh,00fh,0feh,0fch,00ah,081h,0c7h,07ah,0f9h,0fch,00fh,0feh,0fah,00ah	; 61c9  z........z......
	defb 081h,0f4h,07ah,0fch,0f8h,00fh,0f6h,0fdh,009h,081h,01fh,07ch,0feh,0f9h,00fh,0f8h	; 61d9  ..z........|....
	defb 0fch,009h,001h,0fah,009h,081h,058h,07ch,0fdh,0f7h,00fh,0fdh,0fch,009h,0feh,0f9h	; 61e9  ......X|........
	defb 009h,081h,09ah,07ch,0fch,0fch,00fh,0fch,0fch,009h,081h,0d1h,07ch,0fdh,0fch,00fh	; 61f9  ...|........|...
	defb 0fdh,0fah,009h,081h,0feh,07ch	; 6209

; ======================================================================
; CODIGO 0x620f..0x6225  (22 bytes)
; ======================================================================



; ----------------------------------------------------------------------
; ===== LAS DOCE SUBFASES DEL PUNTO =====
; ----------------------------------------------------------------------
reparte_la_subfase:		; despacha (0xE130) sobre la tabla de doce que va pegada detras
	ld hl,0e171h		;620f
	ld a,(0e10ch)		;6212   ; (0xE10C) dice a quien le toca
	and a			;6215
	jr z,L_621B		;6216
	ld hl,0e191h		;6218
L_621B:
	xor a			;621b
	ld (hl),a			;621c   ; y se borra el aviso de golpe del que va a jugar
	ld bc,(0e130h)		;621d   ; C es la subfase y B el paso dentro de ella
	ld a,c			;6221
	call despacha		;6222   ; y la tabla de doce viene pegada aqui detras

; ----------------------------------------------------------------------
; DATOS tabla_de_subescenas: 12 entradas, pegada detras de su call; la primera
;   apunta a 0x623D, justo detras de la tabla
;   0x6225..0x623d  (24 bytes)
DATA_tabla_de_subescenas:
	defw 0623dh,06306h,06328h,0632eh,0655ch,06594h,065b9h,06622h	; 6225
	defw 066dch,067f1h,068f2h,06921h	; 6235  -> L_66DC L_67F1 L_68F2 L_6921

; ======================================================================
; CODIGO 0x623d..0x629f  (98 bytes)
; ======================================================================



; ----------------------------------------------------------------------
; ===== Subfase 0: colocar la pelota para el saque =====
; ----------------------------------------------------------------------
L_623D:
	call pinta_el_marcador		;623d
	ld hl,0629fh		;6240   ; la terna de saque de un lado
	ld a,(0e140h)		;6243   ; (0xE140) dice cual
	and a			;6246
	jr z,L_624C		;6247
	ld hl,062a5h		;6249   ; y la del otro
L_624C:
	ld de,0e100h		;624c
	ld bc,00006h		;624f   ; seis bytes: las tres coordenadas de la pelota, en palabras
	ldir		;6252
	ld a,078h		;6254   ; los dos munecos, a media altura
	ld (0e161h),a		;6256
	ld (0e181h),a		;6259
	ld a,000h		;625c
	ld (0e116h),a		;625e
	ld b,0ffh		;6261   ; 0xFF o 0x00 segun el lado
	ld a,(0e140h)		;6263
	and a			;6266
	jr z,L_626A		;6267
	inc b			;6269
L_626A:
	ld a,b			;626a
	ld (0e10ch),a		;626b   ; (0xE10C): de quien es el turno
	xor a			;626e
	ld (0e171h),a		;626f   ; borra los avisos de golpe de los dos
	ld (0e191h),a		;6272
	ld (0e114h),a		;6275   ; y todo el estado del punto: fase, botes, red, faltas
	ld (0e143h),a		;6278
	ld (0e148h),a		;627b
	ld (0e145h),a		;627e
	ld (0e111h),a		;6281
	ld (0e14ch),a		;6284
	ld (0e147h),a		;6287
	ld (0e150h),a		;628a
	ld (0e1abh),a		;628d
	inc a			;6290
	ld (0e142h),a		;6291   ; (0xE142) a 1
	ld a,010h		;6294
	ld (0e115h),a		;6296   ; (0xE115) a 0x10: la cuenta de la que arranca el saque
	call pon_la_sombra		;6299
	jp avanza_subfase		;629c

; ----------------------------------------------------------------------
; DATOS saque_por_la_izquierda: las tres coordenadas de la pelota al sacar
;   -0x26, 0x78 y 0x34-, que 0x6252 copia a (0xE100)
;   0x629f..0x62a5  (6 bytes)
DATA_saque_por_la_izquierda:
	defw 00026h,00078h,00034h	; 629f

; ----------------------------------------------------------------------
; DATOS saque_por_la_derecha: las mismas dos ultimas con 0x9D de x: el otro
;   lado de la mesa. Lo elige (0xE140) en 0x6243
;   0x62a5..0x62ab  (6 bytes)
DATA_saque_por_la_derecha:
	defw 0009dh,00078h,00034h	; 62a5

; ======================================================================
; CODIGO 0x62ab..0x6799  (1262 bytes)
; ======================================================================



; ----------------------------------------------------------------------
; ===== Subfase 1: el saque =====
; ----------------------------------------------------------------------
L_62AB:
	call pon_la_sombra		;62ab
	ld a,034h		;62ae
	ld (0e104h),a		;62b0   ; (0xE104) es la altura de la pelota en la mano
	ld de,0e009h		;62b3   ; el mando del jugador 1
	ld b,000h		;62b6
	ld a,(0e140h)		;62b8   ; salvo que saque el otro lado
	and a			;62bb
	jr z,L_62CB		;62bc
	ld de,0e049h		;62be
	ld a,(0e002h)		;62c1
	bit 5,a		;62c4
	call z,finge_el_mando		;62c6   ; con un solo jugador, saca la maquina
	ld b,001h		;62c9
L_62CB:
	ld hl,0e141h		;62cb
	ld (hl),b			;62ce   ; (0xE141) anota quien saca
	ld hl,0e102h		;62cf   ; (0xE102) es donde se coloca la pelota antes de lanzarla
	ld a,(hl)			;62d2
	cp 05eh		;62d3   ; por debajo de 0x5E no se puede bajar mas
	ld a,(de)			;62d5
	jr c,L_62DD		;62d6
	bit 2,a		;62d8   ; el bit 2 del mando
	jr z,L_62DD		;62da
	dec (hl)			;62dc
L_62DD:
	ld a,(hl)			;62dd
	cp 0a1h		;62de   ; y por arriba el tope es 0xA1
	ld a,(de)			;62e0
	jr nc,L_62E8		;62e1
	bit 3,a		;62e3
	jr z,L_62E8		;62e5
	inc (hl)			;62e7
L_62E8:
	bit 0,a		;62e8   ; el bit 0 es el boton: soltar la pelota
	ret z			;62ea
	ld hl,0e106h		;62eb
	ld de,0e107h		;62ee
	ld (hl),000h		;62f1   ; borra los cinco bytes de velocidad de la pelota
	ld bc,00004h		;62f3
	ldir		;62f6
	ld a,002h		;62f8   ; y le pone 2 de subida: el lanzamiento
	ld (hl),a			;62fa
	inc hl			;62fb
	xor a			;62fc
	ld (hl),a			;62fd
	ld (0e10eh),a		;62fe   ; (0xE10E), el aviso de golpe, a cero
L_6301:
	ld hl,0e131h		;6301
	inc (hl)			;6304   ; y a la subfase siguiente
	ret			;6305
L_6306:
	djnz L_62AB		;6306   ; subfase 2
	call mira_si_da_en_la_red		;6308
	ld a,(0e104h)		;630b
	cp 033h		;630e   ; por debajo de 0x33 de altura ya no hay saque que valga
	jp c,L_658F		;6310
	ld hl,0e008h		;6313
	ld a,(0e140h)		;6316
	and a			;6319
	jr z,L_631F		;631a
	ld hl,0e048h		;631c
L_631F:
	ld a,(hl)			;631f
	and 00ch		;6320   ; los bits 2 y 3: hay que mover la raqueta para golpear
	ret z			;6322
	ld a,003h		;6323   ; y si se mueve, a la fase 3
	jp pon_la_subfase		;6325
L_6328:
	call L_6E1D		;6328   ; subfase 3
	jp avanza_subfase		;632b
L_632E:
	ld hl,0e11bh		;632e   ; (0xE11A) y (0xE11B) son un contador de 16 bits que se va desplazando
	sla (hl)		;6331
	dec hl			;6333
	rl (hl)		;6334
	jp nc,L_646E		;6336
	inc hl			;6339
	set 0,(hl)		;633a

; ----------------------------------------------------------------------
; ===== LA RED: una caja de tres lados =====
; ----------------------------------------------------------------------
mira_si_da_en_la_red:		; la pelota da en la red si esta dentro de la caja de la red
	ld hl,0e100h		;633c   ; (0xE100) es la coordenada larga de la mesa
	ld a,(hl)			;633f
	cp 05fh		;6340   ; la red va de 0x5F a 0x68: fuera de ahi, no hay red que tocar
	jr c,mueve_la_pelota		;6342
	cp 069h		;6344
	jr nc,mueve_la_pelota		;6346
	inc hl			;6348
	inc hl			;6349
	ld a,(hl)			;634a   ; la segunda coordenada, entre 0x57 y 0xA8: el ancho de la mesa
	cp 057h		;634b
	jr c,mueve_la_pelota		;634d
	cp 0a9h		;634f
	jr nc,mueve_la_pelota		;6351
	inc hl			;6353
	inc hl			;6354
	ld a,(hl)			;6355   ; y la altura: por encima de 0x36 pasa limpia
	cp 036h		;6356
	jr nc,mueve_la_pelota		;6358
	cp 035h		;635a   ; entre 0x35 y 0x36 roza la cinta y sigue
	jr c,L_6388		;635c
	ld a,(0e147h)		;635e   ; (0xE147) es el aviso de que ya se ha cantado
	and a			;6361
	jr nz,L_6368		;6362
	inc a			;6364
	ld (0e148h),a		;6365   ; y si no, se canta: es el LET
L_6368:
	ld hl,07002h		;6368   ; 0x7002 de velocidad: el rebote seco de la red
	ld (0e112h),hl		;636b
	ld a,02ah		;636e   ; (0xE150) a 0x2A
	ld (0e150h),a		;6370
	ld a,(0e10ch)		;6373
	and a			;6376
	ld a,05eh		;6377   ; y la pelota cae a un lado o al otro de la red segun de quien fuera el golpe
	jr nz,L_637D		;6379
	ld a,06ah		;637b
L_637D:
	ld (0e100h),a		;637d
	ld a,00dh		;6380
	call arranca_melodia		;6382
	jp L_6E23		;6385
L_6388:
	ld a,00dh		;6388
	call arranca_melodia		;638a
	ld a,007h		;638d
	jp pon_la_subfase		;638f

; ----------------------------------------------------------------------
; ===== LA PELOTA: un cuadro de vuelo =====
; ----------------------------------------------------------------------
mueve_la_pelota:		; suma las tres velocidades, mira la mesa y aplica la gravedad
	ld hl,0e107h		;6392
	ld a,(0e10ch)		;6395   ; (0xE10C) dice hacia que lado va, o sea si la coordenada sube o baja
	ld de,0e101h		;6398
	and a			;639b
	jr z,L_63A3		;639c
	call resta_velocidad		;639e   ; hacia atras
	jr L_63A6		;63a1
L_63A3:
	call suma_velocidad		;63a3   ; o hacia adelante
L_63A6:
	ld a,(0e10dh)		;63a6   ; (0xE10D) hace lo mismo con el otro eje
	ld de,0e103h		;63a9
	ld hl,0e109h		;63ac
	and a			;63af
	jr nz,L_63B7		;63b0
	call suma_velocidad		;63b2
	jr L_63BA		;63b5
L_63B7:
	call resta_velocidad		;63b7
L_63BA:
	ld a,(0e100h)		;63ba
	cp 02dh		;63bd   ; LA MESA a lo largo: de 0x2D a 0x98
	jr c,L_641F		;63bf
	cp 099h		;63c1
	jr nc,L_641F		;63c3
	ld a,(0e102h)		;63c5
	cp 05eh		;63c8   ; y a lo ancho: de 0x5E a 0xA0
	jr c,L_641F		;63ca
	cp 0a1h		;63cc
	jp nc,L_641F		;63ce
	ld a,030h		;63d1   ; (0xE116) a 0x30: dentro de la mesa, la pelota lleva sombra
	ld (0e116h),a		;63d3
	ld a,(0e104h)		;63d6   ; la altura
	cp 030h		;63d9   ; por encima de 0x30 aun vuela
	jr nc,L_6422		;63db
	cp 026h		;63dd   ; entre 0x26 y 0x30 esta botando
	jp nc,avanza_subfase		;63df
	ld a,008h		;63e2   ; y por debajo, ya ha tocado: fin del punto
	jp pon_la_subfase		;63e4

; ----------------------------------------------------------------------
; ===== La sombra =====
; ----------------------------------------------------------------------
pon_la_sombra:		; decide si la pelota proyecta sombra y de que clase
	ld b,000h		;63e7   ; sin sombra por omision
	ld c,000h		;63e9
	ld a,(0e102h)		;63eb
	cp 05ah		;63ee   ; la horquilla a lo ancho, un poco mas holgada que la de la mesa
	jr c,L_6416		;63f0
	cp 0a5h		;63f2
	jr nc,L_6416		;63f4
	ld a,(0e100h)		;63f6
	cp 02dh		;63f9   ; y a lo largo, de 0x2D a 0xCA
	jr c,L_6416		;63fb
	cp 0cbh		;63fd
	jr nc,L_6416		;63ff
	ld b,0aah		;6401   ; 0xAA: el patron de la sombra
	cp 099h		;6403   ; pasado 0x99 ya es la mitad de fuera
	ld a,(0e104h)		;6405
	jr c,L_6410		;6408
	cp 030h		;640a   ; y ahi la sombra solo sale con la pelota baja
	jr nc,L_6416		;640c
	jr L_6414		;640e
L_6410:
	cp 026h		;6410
	jr nc,L_6416		;6412
L_6414:
	ld c,001h		;6414
L_6416:
	ld a,c			;6416
	ld (0e117h),a		;6417   ; (0xE117) y (0xE116) los lee luego el dibujado
	ld a,b			;641a
	ld (0e116h),a		;641b
	ret			;641e
L_641F:
	call pon_la_sombra		;641f

; ----------------------------------------------------------------------
; ===== La gravedad =====
; ----------------------------------------------------------------------
L_6422:
	ld a,(0e10eh)		;6422   ; (0xE10E) a cero: la pelota aun sube
	ld de,0e105h		;6425
	ld hl,0e10bh		;6428
	and a			;642b
	jr nz,L_644D		;642c
	call suma_velocidad		;642e   ; mientras sube, la coordenada larga avanza al reves
	ld de,0e10bh		;6431
	ld hl,0e115h		;6434   ; (0xE115) es la gravedad
	ld a,(de)			;6437   ; y se RESTA de la velocidad de subida, que va en 16 bits
	sub (hl)			;6438
	ld (de),a			;6439
	jr nc,L_644B		;643a
	dec de			;643c   ; el prestamo, al byte alto
	ld a,(de)			;643d
	sub 001h		;643e
	ld (de),a			;6440
	jr nc,L_644B		;6441
	xor a			;6443   ; cuando la resta se pasa de cero, la velocidad queda a cero
	ld (de),a			;6444
	inc de			;6445
	ld (de),a			;6446
	inc a			;6447
	ld (0e10eh),a		;6448   ; y (0xE10E) a uno: a partir de aqui, cae
L_644B:
	jr L_646E		;644b
L_644D:
	call resta_velocidad		;644d
	call L_6CCD		;6450   ; el rebote
	ld hl,0e104h		;6453
	ld a,(hl)			;6456
	cp 0f0h		;6457   ; por encima de 0xF0 de altura la pelota se ha ido: punto
	jr c,L_6460		;6459
	ld a,00ah		;645b
	jp pon_la_subfase		;645d
L_6460:
	ld de,0e10bh		;6460
	ld hl,0e115h		;6463
	ld a,(de)			;6466
	add a,(hl)			;6467   ; cayendo, la MISMA gravedad se suma en vez de restarse
	ld (de),a			;6468
	jr nc,L_646E		;6469
	dec de			;646b
	ex de,hl			;646c
	inc (hl)			;646d   ; y el acarreo sube al byte alto

; ----------------------------------------------------------------------
; ===== EL GOLPE: primero el jugador cercano =====
; ----------------------------------------------------------------------
L_646E:
	ld a,(0e10ch)		;646e   ; (0xE10C): la pelota tiene que venir hacia el
	and a			;6471
	jr z,L_64CD		;6472
	ld a,(0e147h)		;6474   ; (0xE147) es el aviso de la red
	and a			;6477
	jr z,L_6487		;6478
	ld a,(0e142h)		;647a   ; y (0xE142) el de saque
	and a			;647d
	jr nz,L_64CD		;647e
	ld a,(0e114h)		;6480
	cp 002h		;6483   ; en la fase 2 el golpe cuenta; en las demas no
	jr nz,L_64CD		;6485
L_6487:
	ld a,(0e148h)		;6487   ; (0xE148) marca que ya se ha golpeado en este vuelo
	and a			;648a
	jr nz,L_64CD		;648b
	ld a,(0e164h)		;648d   ; (0xE164) trae el lado hacia el que mira
	bit 1,a		;6490
	ld ix,0e160h		;6492
	ld hl,0e165h		;6496
	call L_5AAD		;6499   ; mira si la pelota le queda a mano
	jr z,L_64CD		;649c   ; y si no, no hay golpe
	ld b,017h		;649e   ; las tres melodias de golpe entre las que se elige
	ld c,05ch		;64a0
	ld d,062h		;64a2
	call suena_el_golpe		;64a4
	ld a,005h		;64a7
	ld (0e16ch),a		;64a9   ; (0xE16C) a 5: el fotograma del golpe
	jp pon_la_subfase		;64ac
suena_el_golpe:		; elige el sonido del golpe segun hacia donde lo dirija
	ld a,(ix+004h)		;64af
	bit 2,a		;64b2   ; el bit 2 lo cambia por el primero
	jr z,L_64B7		;64b4
	ld b,c			;64b6
L_64B7:
	bit 5,a		;64b7   ; y el 5 por el segundo
	jr z,L_64BC		;64b9
	ld b,d			;64bb
L_64BC:
	ld a,(0e14fh)		;64bc   ; (0xE14F): si esta puesto, suena el golpe especial
	and a			;64bf
	jr z,L_64C4		;64c0
	ld b,013h		;64c2
L_64C4:
	ld a,(0e130h)		;64c4
	dec a			;64c7   ; y en la fase 1 el golpe no se oye
	ret z			;64c8
	ld a,b			;64c9
	jp arranca_melodia		;64ca

; ----------------------------------------------------------------------
; ===== Y el mismo golpe para el lejano =====
; ----------------------------------------------------------------------
L_64CD:
	ld a,(0e10ch)		;64cd   ; aqui la pelota tiene que ir hacia el otro lado
	and a			;64d0   ; cero es que la pelota viene hacia el
	jr nz,L_6517		;64d1   ; y si no, no hay golpe que valga
	ld a,(0e147h)		;64d3   ; el roce de red
	and a			;64d6   ; a cero
	jr z,L_64E6		;64d7   ; se mira si ya golpeo
	ld a,(0e142h)		;64d9   ; el saque
	and a			;64dc   ; a cero
	jr nz,L_6517		;64dd   ; y con saque pendiente, no
	ld a,(0e114h)		;64df   ; la fase del intercambio
	cp 002h		;64e2   ; la 2
	jr nz,L_6517		;64e4   ; y fuera de ella, tampoco
L_64E6:
	ld a,(0e148h)		;64e6   ; (0xE148): si ya se golpeo en este vuelo
	and a			;64e9   ; a cero
	jr nz,L_6517		;64ea
	ld a,(0e184h)		;64ec
	cpl			;64ef   ; el `cpl` invierte el lado: el de enfrente mira al reves
	bit 1,a		;64f0
	ld ix,0e180h		;64f2
	ld hl,0e185h		;64f6
	call L_5AAD		;64f9
	jr z,L_6517		;64fc
	ld a,(0e002h)		;64fe
	bit 5,a		;6501
	call z,elige_la_trayectoria		;6503   ; con un jugador solo, la maquina decide el golpe
	ld b,015h		;6506   ; sus tres melodias son distintas de las del cercano
	ld c,059h		;6508
	ld d,05fh		;650a
	call suena_el_golpe		;650c
	ld a,006h		;650f
	ld (0e18ch),a		;6511   ; (0xE18C) a 6
	jp pon_la_subfase		;6514

; ----------------------------------------------------------------------
; ===== Los limites de la sala =====
; ----------------------------------------------------------------------
L_6517:
	ld a,(0e100h)		;6517
	cp 010h		;651a   ; por debajo de 0x10 la pelota se ha ido del todo: punto
	jr nc,L_6522		;651c
	ld a,008h		;651e
	jr pon_la_subfase		;6520
L_6522:
	ld hl,0e100h		;6522
	ld a,(hl)			;6525
	cp 0e5h		;6526   ; el fondo, en 0xE5
	ld b,0e4h		;6528   ; y rebota justo antes
	ld de,0e10ch		;652a   ; invirtiendo el sentido de (0xE10C)
	jr nc,L_6540		;652d
	inc hl			;652f
	inc hl			;6530
	ld a,(hl)			;6531
	cp 041h		;6532   ; y a lo ancho, las dos paredes
	ld b,042h		;6534   ; la de 0x41
	ld de,0e10dh		;6536
	jr c,L_6540		;6539
	cp 0bch		;653b
	ld b,0bbh		;653d   ; y la de 0xBC
	ret c			;653f
L_6540:
	ld (hl),b			;6540   ; deja la pelota justo en el borde
	ld a,(de)			;6541   ; y le da la vuelta al sentido de ese eje: eso es el rebote
	and a			;6542
	ld a,0ffh		;6543
	jr z,L_6549		;6545
	ld a,000h		;6547
L_6549:
	ld (de),a			;6549
	xor a			;654a
	ld (0e10ah),a		;654b   ; borra la velocidad de subida, los 16 bits
	ld (0e10bh),a		;654e
	ld (0e106h),a		;6551
	ld (0e108h),a		;6554
	inc a			;6557
	ld (0e10eh),a		;6558   ; y la deja cayendo
	ret			;655b
L_655C:
	ld a,003h		;655c
	call arranca_melodia		;655e   ; melodia 3
	ld b,090h		;6561   ; 0x90 de fuerza
	ld a,(0e114h)		;6563
	cp 003h		;6566   ; pasada la fase 3, 0xF0: mas seco
	jr c,L_656C		;6568
	ld b,0f0h		;656a
L_656C:
	ld a,030h		;656c
	ld c,000h		;656e
	call L_6C53		;6570
L_6573:
	ld a,(0e114h)		;6573
	cp 004h		;6576   ; y a partir de la 4 el punto se acaba de otra manera
	jr c,L_657E		;6578
	ld a,008h		;657a
	jr pon_la_subfase		;657c
L_657E:
	ld a,003h		;657e
	jr pon_la_subfase		;6580
L_6582:
	xor a			;6582

; ----------------------------------------------------------------------
; ===== Las tres puertas para cambiar de subfase =====
; ----------------------------------------------------------------------
pon_la_subfase:		; deja (0xE130) en A y reinicia el paso
	ld (0e130h),a		;6583
	jr L_658F		;6586
espera_y_avanza_subfase:		; deja A cuadros en (0xE004) y avanza
	ld (0e004h),a		;6588
avanza_subfase:		; sube (0xE130) al escalon siguiente
	ld hl,0e130h		;658b
	inc (hl)			;658e
L_658F:
	xor a			;658f
L_6590:
	ld (0e131h),a		;6590   ; (0xE131), el paso dentro de la subfase, vuelve a cero
	ret			;6593

; ----------------------------------------------------------------------
; ===== El efecto que se le da a la pelota =====
; ----------------------------------------------------------------------
efecto_del_cercano:		; con la curva que toque segun hacia donde mire
	ld a,(0e147h)		;6594   ; tras un roce de red no hay efecto que valga
	and a			;6597
	jr nz,L_659F		;6598
	call efecto_por_el_centro		;659a   ; la curva plana
	jr L_65B3		;659d
L_659F:
	ld hl,06f11h		;659f   ; la curva que sube
	ld a,(0e164h)		;65a2   ; el bit 1 de (0xE164) es el lado hacia el que mira
	bit 1,a		;65a5
	jr z,L_65AC		;65a7
	ld hl,06f23h		;65a9   ; y la que baja
L_65AC:
	ld a,(0e167h)		;65ac   ; (0xE167) es el punto de la curva
	rra			;65af   ; a la mitad: la curva se recorre de dos en dos
	call saca_el_efecto		;65b0
L_65B3:
	ld hl,0e164h		;65b3
	xor a			;65b6
	jr L_65E4		;65b7
efecto_del_lejano:		; lo mismo para el de enfrente
	ld a,(0e147h)		;65b9
	and a			;65bc
	jr nz,L_65C4		;65bd
	call efecto_por_el_centro		;65bf
	jr L_65DF		;65c2
L_65C4:
	ld a,(0e002h)		;65c4
	bit 5,a		;65c7   ; con un solo jugador, el de enfrente no da efecto
	jr z,L_65DF		;65c9
	ld hl,06f11h		;65cb
	ld a,(0e184h)		;65ce
	bit 1,a		;65d1
	jr nz,L_65D8		;65d3
	ld hl,06f23h		;65d5
L_65D8:
	ld a,(0e187h)		;65d8
	rra			;65db
	call saca_el_efecto		;65dc
L_65DF:
	ld hl,0e184h		;65df
	ld a,001h		;65e2
L_65E4:
	ld (0e141h),a		;65e4   ; (0xE141) a 1
	ld a,(0e14fh)		;65e7   ; (0xE14F) es el golpe especial
	and a			;65ea
	jr z,L_65F7		;65eb
	ld a,(hl)			;65ed
	and 00fh		;65ee   ; deja el nibble bajo y le pone el 0x40
	or 040h		;65f0
	ld (hl),a			;65f2
	ld a,001h		;65f3
	jr L_65FF		;65f5
L_65F7:
	bit 2,(hl)		;65f7   ; y si no, el bit 2 decide
	ld a,000h		;65f9
	jr z,L_65FF		;65fb
	ld a,001h		;65fd
L_65FF:
	ld (0e110h),a		;65ff   ; (0xE110) marca la clase de golpe que ha salido
	call elige_el_golpe		;6602
	call pon_la_fuerza		;6605
	ld hl,0e114h		;6608
	ld a,(hl)			;660b   ; (0xE114) es la fase del intercambio
	and a			;660c
	jr z,L_6611		;660d
	ld a,001h		;660f
L_6611:
	ld (hl),a			;6611
	ld (0e142h),a		;6612   ; (0xE142) a 1: hay saque pendiente
	xor a			;6615
	ld (0e143h),a		;6616
	ld hl,0e145h		;6619
	inc (hl)			;661c   ; (0xE145) cuenta los puntos jugados
	ld a,002h		;661d
	jp pon_la_subfase		;661f
L_6622:
	ld hl,02000h		;6622   ; 0x2000 de velocidad: el bote en la mesa
	ld (0e112h),hl		;6625
	ld a,01eh		;6628
	ld (0e150h),a		;662a   ; (0xE150) a 0x1E
	ld a,(0e10ch)		;662d   ; la pelota vuelve a un lado o a otro segun quien golpeara
	and a			;6630
	ld a,05eh		;6631
	jr z,L_6637		;6633
	ld a,06ah		;6635
L_6637:
	ld (0e100h),a		;6637
	ld (0e143h),a		;663a
	call L_6E1D		;663d
	ld a,003h		;6640
	jp pon_la_subfase		;6642

; ----------------------------------------------------------------------
; ===== EL CANTE DEL ARBITRO =====
; ----------------------------------------------------------------------
L_6645:
	ld a,(0e114h)		;6645   ; en la fase 1 sigue habiendo saque
	dec a			;6648
	jr nz,L_664F		;6649
	inc a			;664b
	ld (0e142h),a		;664c
L_664F:
	ld b,000h		;664f   ; B es el cante que va a salir, y se arma mirando los avisos
	ld a,(0e148h)		;6651   ; (0xE148): si nadie golpeo, se queda en el primero
	and a			;6654
	jr nz,L_666D		;6655
	inc b			;6657
	ld a,(0e143h)		;6658   ; (0xE143): el bote
	and a			;665b
	jr nz,L_666D		;665c
	inc b			;665e
	ld a,(0e142h)		;665f   ; (0xE142): el saque
	and a			;6662
	jr nz,L_666D		;6663
	inc b			;6665
	ld a,(0e14ch)		;6666   ; y (0xE14C) devuelve uno atras
	and a			;6669
	jr z,L_666D		;666a
	dec b			;666c
L_666D:
	push bc			;666d
	ld hl,0679dh		;666e   ; la tabla de los cuatro rotulos: LET, NET, OUT e IN
	ld a,b			;6671
	add a,a			;6672
	call suma_a_hl		;6673
	ld e,(hl)			;6676
	inc hl			;6677
	ld d,(hl)			;6678
	ld hl,03923h		;6679   ; el sitio donde se escriben
	ld a,(0e141h)		;667c   ; (0xE141) dice de quien es
	ld b,a			;667f
	ld a,(0e04bh)		;6680   ; y con cambio de campo, del otro
	and a			;6683
	jr z,L_6687		;6684
	dec b			;6686
L_6687:
	ld a,b			;6687
	and a			;6688
	jr nz,L_668E		;6689
	ld hl,0393ah		;668b   ; entonces el rotulo va al otro lado de la pantalla
L_668E:
	call L_475C		;668e   ; sin cabecera: el destino ya esta en HL
	pop bc			;6691
	ld hl,06799h		;6692   ; y el sonido del cante sale de la tabla hermana
	ld a,b			;6695
	call suma_a_hl		;6696
	ld a,(hl)			;6699
	call suena_si_hay_partida		;669a   ; que solo suena dentro de la partida
	ld a,010h		;669d
	ld (0e100h),a		;669f   ; la pelota vuelve al principio
	ld (0e104h),a		;66a2
	ld a,080h		;66a5
	ld (0e102h),a		;66a7   ; en medio a lo ancho
	xor a			;66aa
	ld (0e117h),a		;66ab   ; y sin sombra
	ld a,03ah		;66ae
	ld (0e162h),a		;66b0   ; los dos munecos, a 0x3A
	ld (0e182h),a		;66b3
	ld a,030h		;66b6
	ld (0e004h),a		;66b8   ; 0x30 cuadros para leer el cante
	jp L_6301		;66bb
L_66BE:
	djnz L_6645		;66be   ; subfase 4
	ld a,068h		;66c0
	call suena_si_hay_partida		;66c2   ; melodia 0x68
	ld de,06d75h		;66c5   ; el guion de la columna lateral
	ld a,(0e14bh)		;66c8   ; (0xE14B) elige cual de las dos
	and a			;66cb
	jr z,L_66D1		;66cc
	ld de,06db1h		;66ce
L_66D1:
	call pinta_rotulo		;66d1
	ld a,080h		;66d4
	ld (0e004h),a		;66d6   ; la espera para leer el rotulo
	jp avanza_subfase		;66d9
L_66DC:
	djnz L_66BE		;66dc   ; subfase 5
	ld hl,0e004h		;66de
	dec (hl)			;66e1
	ret nz			;66e2
	ld a,(0e148h)		;66e3   ; si hubo golpe, el punto se resuelve por otro camino
	and a			;66e6
	jp nz,avanza_subfase		;66e7
	ld de,0e132h		;66ea   ; (0xE132) y (0xE133): los dos tanteos del set
	ld a,(0e141h)		;66ed   ; (0xE141) dice de quien fue el ultimo golpe
	and a			;66f0
	jr nz,L_6701		;66f1
	ld a,(0e142h)		;66f3   ; (0xE142), si el fallo fue en el saque
	and a			;66f6
	jr nz,L_670D		;66f7
	ld a,(0e14ch)		;66f9   ; y (0xE14C), la otra clase de fallo
	and a			;66fc
	jr nz,L_670D		;66fd
	jr L_6735		;66ff
L_6701:
	ld a,(0e142h)		;6701   ; el saque
	and a			;6704   ; a cero
	jr nz,L_6735		;6705   ; y con saque pendiente, por el otro camino
	ld a,(0e14ch)		;6707   ; la falta
	and a			;670a   ; a cero
	jr nz,L_6735		;670b   ; y con falta, tambien
L_670D:
	ld a,(0e002h)		;670d   ; el modo
	bit 5,a		;6710   ; con un jugador solo no hay cambio de lado
	jr z,L_6730		;6712   ; con un jugador no hay cambio de campo
	ld a,(0e053h)		;6714   ; (0xE053) es el set
	dec a			;6717
	jr z,L_6758		;6718   ; en el primero, siempre
	dec a			;671a
	jr nz,L_6730		;671b
	ld a,(0e14ah)		;671d   ; y en el tercero solo cuando aun no se ha cambiado
	and a			;6720
	jr nz,L_6758		;6721
	ld b,002h		;6723
	ld hl,0e132h		;6725
L_6728:
	ld a,(hl)			;6728
	cp 010h		;6729   ; en BCD, 0x10 son DIEZ puntos: ahi es donde se cambia de lado en el set decisivo
	jr nc,L_6758		;672b
	inc hl			;672d
	djnz L_6728		;672e
L_6730:
	inc de			;6730
	ld a,001h		;6731
	jr L_6759		;6733
L_6735:
	ld a,(0e002h)		;6735   ; el modo
	bit 5,a		;6738   ; sin dos jugadores no hay cambio
	jr z,L_6758		;673a   ; y se sigue
	ld a,(0e053h)		;673c   ; el set
	dec a			;673f   ; en el primero
	jr z,L_6730		;6740   ; siempre
	dec a			;6742   ; en el segundo, no
	jr nz,L_6758		;6743   ; y de ahi arriba, tampoco
	ld a,(0e14ah)		;6745   ; (0xE14A), el deuce
	and a			;6748   ; a cero
	jr nz,L_6730		;6749   ; y con deuce, siempre
	ld b,002h		;674b   ; los dos tanteos
	ld hl,0e132h		;674d   ; desde el primero
L_6750:
	ld a,(hl)			;6750   ; el de este
	cp 010h		;6751   ; al llegar a diez
	jr nc,L_6730		;6753   ; se cambia
	inc hl			;6755   ; y si no, el del otro
	djnz L_6750		;6756   ; los dos
L_6758:
	xor a			;6758
L_6759:
	ld (0e14bh),a		;6759   ; (0xE14B) anota de que lado cae el punto
	ex de,hl			;675c
	push af			;675d

; ----------------------------------------------------------------------
; ===== El tanteo, en BCD =====
; ----------------------------------------------------------------------
	ld a,(hl)			;675e   ; el tanteo de quien gana el punto
	add a,001h		;675f   ; uno mas
	daa			;6761   ; y el `daa` lo deja en decimal codificado: los dos digitos se leen a ojo del byte
	ld (hl),a			;6762
	ld hl,0e054h		;6763   ; (0xE054) y (0xE057) son los tanteos de set de cada jugador
	ld de,0e057h		;6766
	ld a,(0e053h)		;6769   ; indexados por el set que se juega
	push af			;676c
	call suma_a_hl		;676d
	pop af			;6770
	call suma_a_de		;6771
	pop af			;6774
	and a			;6775
	jr z,L_6779		;6776
	ex de,hl			;6778   ; y se cruzan si el punto fue del otro
L_6779:
	ld a,(hl)			;6779
	add a,001h		;677a
	daa			;677c   ; otra suma en BCD
	ld (hl),a			;677d
	ld a,(hl)			;677e
	and a			;677f
	jr nz,L_6796		;6780
	ld a,006h		;6782
	call suma_a_hl		;6784   ; seis mas alla estan los sets ganados
	ld a,006h		;6787
	call suma_a_de		;6789
	ld a,001h		;678c
	ld (hl),a			;678e   ; y se le apunta uno
	ld a,(de)			;678f
	and a			;6790
	jr z,L_6796		;6791
	xor a			;6793
	ld (hl),a			;6794
	ld (de),a			;6795   ; si los dos lo tienen, se borran los dos
L_6796:
	jp L_6301		;6796

; ----------------------------------------------------------------------
; DATOS melodias_de_los_cantes: las melodias 8, 7, 11 y 9, una por cante,
;   indexadas por el mismo B que elige el rotulo en 0x6692
;   0x6799..0x679d  (4 bytes)
DATA_melodias_de_los_cantes:
	defb 008h	; 6799
	defb 007h	; 679a
	defb 00bh	; 679b
	defb 009h	; 679c

; ----------------------------------------------------------------------
; DATOS tabla_de_cantes: 4 entradas: 0x67A5, 0x67A9, 0x67AD y 0x67B1. La
;   indexa 0x666E con el B que arma 0x664F a base de mirar los avisos del
;   punto
;   0x679d..0x67a5  (8 bytes)
DATA_tabla_de_cantes:
	defw 067a5h,067a9h,067adh,067b1h	; 679d  -> DATA_guiones_de_cantes 0x67a9 0x67ad 0x67b1

; ----------------------------------------------------------------------
; DATOS guiones_de_cantes: los cuatro cantes del arbitro, sin destino delante:
;   "LET", "NET", "OUT" e "IN"
;   0x67a5..0x67b4  (15 bytes)
DATA_guiones_de_cantes:
	defb 02ch,025h,034h,0ffh,02eh,025h,034h,0ffh,02fh,035h,034h,0ffh,029h,02eh,0ffh	; 67a5  ,%4..%4./54.)..

; ======================================================================
; CODIGO 0x67b4..0x68ea  (310 bytes)
; ======================================================================


L_67B4:
	ld a,(0e148h)		;67b4   ; subfase 6
	and a			;67b7
	jp nz,L_6301		;67b8
	call L_6CFB		;67bb   ; recoloca a los munecos
	call L_6DED		;67be   ; y repinta las columnas laterales
	ld hl,0e004h		;67c1
	dec (hl)			;67c4
	ret nz			;67c5
	call L_444F		;67c6
	ld hl,0e052h		;67c9
	inc (hl)			;67cc   ; (0xE052): la pantalla se vuelve a montar
	jp L_6301		;67cd
L_67D0:
	djnz L_67DD		;67d0   ; subfase 7
	ld hl,0e004h		;67d2
	dec (hl)			;67d5
	ret nz			;67d6
	call L_45E8		;67d7
	jp L_6582		;67da
L_67DD:
	djnz L_67B4		;67dd   ; subfase 8
	ld hl,0e004h		;67df
	dec (hl)			;67e2
	ret nz			;67e3
	call L_6E08		;67e4
	ld a,060h		;67e7   ; 0x60 cuadros de espera
	ld (0e004h),a		;67e9
	ld a,002h		;67ec
	jp L_6590		;67ee
L_67F1:
	djnz L_67D0		;67f1   ; subfase 9
	ld hl,03923h		;67f3   ; borra el rotulo del cante de un lado
	ld bc,00003h		;67f6
	ld a,006h		;67f9
	call 00056h		;67fb   ; BIOS FILVRM - Fills VRAM with value
	ld hl,0393ah		;67fe   ; y del otro: tres tiles cada uno, con el patron 6
	ld bc,00003h		;6801
	ld a,006h		;6804
	call 00056h		;6806   ; BIOS FILVRM - Fills VRAM with value
	call L_6CF5		;6809

; ----------------------------------------------------------------------
; ===== LAS REGLAS: 21 puntos, y ganar por dos =====
; ----------------------------------------------------------------------
	ld a,(0e148h)		;680c
	and a			;680f
	jp nz,L_68AC		;6810
	ld hl,0e132h		;6813   ; los dos tanteos del set
	ld b,002h		;6816
L_6818:
	ld a,(hl)			;6818
	cp 020h		;6819   ; en BCD, 0x20 son VEINTE
	jr nz,L_6825		;681b
	inc hl			;681d
	djnz L_6818		;681e
	ld a,001h		;6820
	ld (0e14ah),a		;6822   ; (0xE14A) a 1: los dos a veinte, o sea DEUCE
L_6825:
	ld hl,0e132h		;6825
	ld a,(hl)			;6828
	cp 021h		;6829   ; y si los dos llegan a 21
	jr nz,L_6837		;682b
	inc hl			;682d
	ld a,(hl)			;682e
	cp 021h		;682f
	jr nz,L_6837		;6831
	xor a			;6833   ; se les devuelve a cero: en el deuce el marcador se reinicia
	ld (hl),a			;6834
	dec hl			;6835
	ld (hl),a			;6836
L_6837:
	ld a,(0e14ah)		;6837
	and a			;683a
	jr nz,L_684C		;683b
	ld hl,0e132h		;683d   ; y aqui, el cambio de saque
	ld a,(hl)			;6840
	inc hl			;6841
	add a,(hl)			;6842   ; la suma de los dos tanteos
	daa			;6843   ; en decimal
	and 00fh		;6844   ; mirando solo el digito de las unidades
	jr z,L_684C		;6846   ; cada cinco puntos jugados
	cp 005h		;6848   ; o sea al 0 y al 5
	jr nz,L_6852		;684a
L_684C:
	ld de,0e140h		;684c
	ld a,(de)			;684f
	cpl			;6850   ; el `cpl` da la vuelta a (0xE140): saca el otro
	ld (de),a			;6851
L_6852:
	ld a,(0e14ah)		;6852
	and a			;6855
	jr z,L_685E		;6856
	ld hl,0e133h		;6858   ; en el deuce, el que decide es el segundo tanteo
	ld a,(hl)			;685b
	jr L_686C		;685c
L_685E:
	ld hl,0e132h		;685e
	ld a,(hl)			;6861
	cp 020h		;6862   ; por debajo de veinte no hay nada que mirar
	jr c,L_6886		;6864
	inc hl			;6866
	ld a,(hl)			;6867
	cp 020h		;6868
	jr c,L_6886		;686a
L_686C:
	dec hl			;686c   ; la diferencia entre los dos tanteos
	ld de,0e051h		;686d
	ld c,001h		;6870
	sub (hl)			;6872   ; empatados, no gana nadie
	jr z,L_68D7		;6873
	jr nc,L_687B		;6875
	dec de			;6877
	neg		;6878   ; y si el que gana es el otro, se le da la vuelta
	dec c			;687a
L_687B:
	ex de,hl			;687b
	cp 002h		;687c   ; DOS de diferencia. Y tambien vale 8, porque la resta es BINARIA sobre BCD: 21 menos 19 da 0x08, y son dos puntos igual
	jr z,L_6895		;687e
	cp 008h		;6880
	jr z,L_6895		;6882
	jr L_68AC		;6884
L_6886:
	ld de,0e132h		;6886
	ld hl,0e050h		;6889
	ld c,000h		;688c
	ld b,002h		;688e
L_6890:
	ld a,(de)			;6890
	cp 021h		;6891   ; 0x21 en BCD: VEINTIUNO, el set ganado
	jr c,L_68A7		;6893
L_6895:
	inc (hl)			;6895   ; y se le apunta el set
	ld a,c			;6896
	ld (0e14dh),a		;6897   ; (0xE14D) dice quien lo gano
	ld hl,0e053h		;689a
	inc (hl)			;689d   ; (0xE053) pasa al set siguiente
	xor a			;689e
	ld (0e14ah),a		;689f   ; y el deuce se olvida
	ld a,00bh		;68a2   ; y a la subfase 11
	jp pon_la_subfase		;68a4
L_68A7:
	inc hl			;68a7
	inc de			;68a8
	inc c			;68a9
	djnz L_6890		;68aa
L_68AC:
	ld a,(0e002h)		;68ac
	bit 5,a		;68af   ; sin dos jugadores no hay cambio de campo
	jr z,L_68D4		;68b1
	ld a,(0e134h)		;68b3   ; (0xE134) es el pestillo, para no cambiar dos veces
	and a			;68b6
	jp nz,L_68D4		;68b7
	ld a,(0e053h)		;68ba
	cp 002h		;68bd   ; solo en el tercer set
	jr nz,L_68D4		;68bf
	ld a,(0e04bh)		;68c1   ; y solo si el cambio esta pedido
	and a			;68c4
	jr z,L_68D4		;68c5
	ld a,010h		;68c7
	ld (0e004h),a		;68c9
	ld (0e134h),a		;68cc
	ld a,003h		;68cf
	jp L_6590		;68d1
L_68D4:
	jp L_6582		;68d4

; ----------------------------------------------------------------------
; ===== El deuce =====
; ----------------------------------------------------------------------
L_68D7:
	ld a,02bh		;68d7   ; melodia 0x2B
	call suena_si_hay_partida		;68d9
	ld de,068eah		;68dc   ; el rotulo DEUCE
	call pinta_rotulo		;68df
	ld a,060h		;68e2
	ld (0e004h),a		;68e4   ; 0x60 cuadros para leerlo
	jp L_6301		;68e7

; ----------------------------------------------------------------------
; DATOS guion_deuce: "DEUCE" en 0x398D, el empate a veinte que reinicia el
;   marcador
;   0x68ea..0x68f2  (8 bytes)
DATA_guion_deuce:
	defb 08dh,039h,024h,025h,035h,023h,025h,0ffh	; 68ea  .9$%5#%.

; ======================================================================
; CODIGO 0x68f2..0x69b7  (197 bytes)
; ======================================================================


L_68F2:
	ld a,042h		;68f2
	call arranca_melodia		;68f4   ; melodia 0x42: el punto que se pierde
	ld b,0f0h		;68f7
	xor a			;68f9
	ld (0e110h),a		;68fa   ; la clase de golpe y la altura, a cero
	ld (0e104h),a		;68fd
	ld c,001h		;6900
	call L_6C53		;6902
	ld a,(0e114h)		;6905
	cp 002h		;6908
	jp nz,L_6573		;690a
	ld hl,0e106h		;690d
	ld b,004h		;6910   ; mira los cuatro bytes de velocidad de la pelota
L_6912:
	ld a,(hl)			;6912
	and a			;6913
	jr nz,L_691E		;6914
	inc hl			;6916
	djnz L_6912		;6917
	ld a,008h		;6919   ; si estan todos a cero, la pelota esta parada: subfase 8
	jp pon_la_subfase		;691b
L_691E:
	jp L_6573		;691e
L_6921:
	djnz L_6930		;6921   ; subfase 10
	ld hl,0e004h		;6923
	dec (hl)			;6926
	ret nz			;6927
	ld a,0aeh		;6928
	call suena_si_hay_partida		;692a   ; melodia 0xAE
	jp L_6301		;692d
L_6930:
	djnz L_6966		;6930   ; subfase 11
	call sprite_del_ganador		;6932
	call vuelca_los_sprites		;6935
	call parpadea_el_ganador		;6938
	ld a,(0e003h)		;693b
	bit 3,a		;693e   ; el bit 3 del reloj de cuadros: PARPADEA cuatro veces por segundo
	jr z,L_6947		;6940
	call pinta_los_nombres		;6942   ; con el bit puesto se pinta el rotulo
	jr L_695A		;6945
L_6947:
	ld hl,03989h		;6947
	ld a,(0e14dh)		;694a   ; (0xE14D) es quien gano el set
	and a			;694d
	jr z,L_6953		;694e
	ld hl,039a9h		;6950
L_6953:
	xor a			;6953
	ld bc,00003h		;6954
	call 00056h		;6957   ; BIOS FILVRM - Fills VRAM with value | y con el bit apagado se borra: eso es lo que parpadea
L_695A:
	ld a,(0e012h)		;695a   ; mientras el canal 1 siga sonando, no se pasa
	and a			;695d
	ret nz			;695e
	call pinta_los_nombres		;695f
	ld a,040h		;6962
	jr L_698A		;6964
L_6966:
	djnz L_697C		;6966
	call sprite_del_ganador_fijo		;6968
	call vuelca_los_sprites		;696b
	ld hl,0e004h		;696e
	dec (hl)			;6971   ; y cuando se agota la espera
	ret nz			;6972
	call esconde_casi_todos		;6973
	ld a,001h		;6976
	ld (0e00dh),a		;6978   ; (0xE00D) a 1: la partida ha terminado
	ret			;697b
L_697C:
	call L_7DED		;697c   ; la pantalla de nombres entera
	call esconde_los_sprites		;697f
	call L_44B9		;6982
	call borra_el_marcador		;6985
	ld a,030h		;6988   ; 0x30 cuadros
L_698A:
	ld (0e004h),a		;698a
	jp L_6301		;698d
esconde_los_sprites:		; 0xE0 en los 0x4C primeros bytes: todos fuera de la pantalla
	ld b,04ch		;6990
	ld a,0e0h		;6992
	ld hl,0e070h		;6994
L_6997:
	ld (hl),a			;6997
	inc hl			;6998
	djnz L_6997		;6999
	ret			;699b

; ----------------------------------------------------------------------
; ===== El rotulo del ganador, parpadeando =====
; ----------------------------------------------------------------------
parpadea_el_ganador:		; alterna entre dos guiones con el bit 3 del reloj
	ld a,(0e14dh)		;699c
	ld hl,069b7h		;699f   ; los guiones de un ganador
	and a			;69a2
	jr z,L_69A8		;69a3
	ld hl,069bbh		;69a5   ; o los del otro
L_69A8:
	ld a,(0e003h)		;69a8
	bit 3,a		;69ab   ; y de cada par, uno pinta y el otro borra
	jr z,L_69B1		;69ad
	inc hl			;69af
	inc hl			;69b0
L_69B1:
	ld e,(hl)			;69b1
	inc hl			;69b2
	ld d,(hl)			;69b3
	jp pinta_rotulo		;69b4

; ----------------------------------------------------------------------
; DATOS tabla_de_guiones_a: 2 entradas, 0x69BF y 0x69D0; la lee 0x699F
;   0x69b7..0x69bb  (4 bytes)
DATA_tabla_de_guiones_a:
	defw 069bfh,069d0h	; 69b7  -> DATA_guiones_del_tanteo 0x69d0

; ----------------------------------------------------------------------
; DATOS tabla_de_guiones_b: 2 entradas, 0x69E1 y 0x69F0; la lee 0x69A5
;   0x69bb..0x69bf  (4 bytes)
DATA_tabla_de_guiones_b:
	defw 069e1h,069f0h	; 69bb

; ----------------------------------------------------------------------
; DATOS guiones_del_tanteo: los cuatro guiones que apuntan esas dos tablas,
;   con destino delante y varios tramos cada uno
;   0x69bf..0x69ff  (64 bytes)
DATA_guiones_del_tanteo:
	defb 05ch,038h,04dh,04eh,04fh,0feh,07ch,038h,0b6h,09bh,051h,0feh,09dh,038h,052h,053h	; 69bf  \8MNO.|8..Q..8RS
	defb 0ffh,05ch,038h,098h,04eh,09ah,0feh,07ch,038h,091h,099h,092h,0feh,09dh,038h,093h	; 69cf  .\8.N..|8.....8.
	defb 094h,0ffh,05dh,038h,08ah,08bh,0feh,07dh,038h,08ch,08fh,0feh,09dh,038h,08dh,08eh	; 69df  ..]8...}8....8..
	defb 0ffh,05dh,038h,095h,096h,0feh,07dh,038h,097h,090h,0feh,09dh,038h,08dh,08eh,0ffh	; 69ef  .]8...}8....8...

; ======================================================================
; CODIGO 0x69ff..0x6a3b  (60 bytes)
; ======================================================================



; ----------------------------------------------------------------------
; ===== Y su sprite, igual =====
; ----------------------------------------------------------------------
sprite_del_ganador_fijo:		; la misma tabla, pero sin parpadeo
	ld b,001h		;69ff
	jr L_6A05		;6a01
sprite_del_ganador:		; cuatro bytes de atributo, alternando con el reloj
	ld b,000h		;6a03
L_6A05:
	ld hl,06a3bh		;6a05
	ld de,06a3fh		;6a08
	ld a,(0e14dh)		;6a0b
	and a			;6a0e
	jr z,L_6A12		;6a0f
	ex de,hl			;6a11   ; se cruzan si gano el otro
L_6A12:
	ld a,(0e002h)		;6a12
	bit 5,a		;6a15
	jr z,L_6A21		;6a17
	ld a,(0e053h)		;6a19   ; y en el primer set no se cruzan
	cp 001h		;6a1c
	jr z,L_6A21		;6a1e
	ex de,hl			;6a20
L_6A21:
	ld a,b			;6a21
	and a			;6a22
	jr nz,L_6A2C		;6a23
	ld a,(0e003h)		;6a25
	bit 3,a		;6a28   ; aqui vuelve a mandar el bit 3 del reloj
	jr z,L_6A2E		;6a2a
L_6A2C:
	inc hl			;6a2c
	inc hl			;6a2d
L_6A2E:
	ld e,(hl)			;6a2e
	inc hl			;6a2f
	ld d,(hl)			;6a30
	ex de,hl			;6a31
	ld de,0e070h		;6a32
	ld bc,00004h		;6a35
	ldir		;6a38   ; los cuatro bytes del sprite: y, x, patron y color
	ret			;6a3a

; ----------------------------------------------------------------------
; DATOS tabla_de_ternas_a: 2 entradas, 0x6A43 y 0x6A47; la lee 0x6A05
;   0x6a3b..0x6a3f  (4 bytes)
DATA_tabla_de_ternas_a:
	defw 06a43h,06a47h	; 6a3b  -> DATA_cuatro_ternas 0x6a47

; ----------------------------------------------------------------------
; DATOS tabla_de_ternas_b: 2 entradas, 0x6A4B y 0x6A4F; la lee 0x6A08
;   0x6a3f..0x6a43  (4 bytes)
DATA_tabla_de_ternas_b:
	defw 06a4bh,06a4fh	; 6a3f

; ----------------------------------------------------------------------
; DATOS cuatro_ternas: cuatro registros de cuatro bytes que apuntan las dos
;   tablas de arriba
;   0x6a43..0x6a53  (16 bytes)
DATA_cuatro_ternas:
	defb 0a2h,078h,058h,00fh	; 6a43
	defb 0a0h,075h,05ch,00fh	; 6a47
	defb 013h,078h,060h,00fh	; 6a4b
	defb 010h,075h,064h,00fh	; 6a4f

; ======================================================================
; CODIGO 0x6a53..0x6a9c  (73 bytes)
; ======================================================================


pon_la_fuerza:		; saca de las dos tablas la fuerza y el alcance del golpe
	ld de,06aa8h		;6a53
	ld a,b			;6a56
	call suma_a_de		;6a57
	ld a,(de)			;6a5a
	ld (0e150h),a		;6a5b   ; (0xE150) es el alcance
	ld a,006h		;6a5e
	call suma_a_de		;6a60   ; seis mas alla esta el otro valor
	ld a,(de)			;6a63
	ld (0e111h),a		;6a64   ; (0xE111)
	ret			;6a67

; ----------------------------------------------------------------------
; ===== La direccion del golpe sale del mando =====
; ----------------------------------------------------------------------
elige_el_golpe:		; de los bits del mando salen la subida y la velocidad de la pelota
	ld b,002h		;6a68   ; dos por omision
	ld a,(hl)			;6a6a
	rra			;6a6b   ; cinco desplazamientos dejan el bit 5 en el acarreo
	rra			;6a6c
	rra			;6a6d
	rra			;6a6e
	rra			;6a6f
	jr c,L_6A7D		;6a70
	inc b			;6a72   ; cada direccion cambia el indice
	inc b			;6a73
	rra			;6a74
	jr c,L_6A7D		;6a75
	inc b			;6a77
	rra			;6a78
	jr c,L_6A7D		;6a79
	dec b			;6a7b
	dec b			;6a7c
L_6A7D:
	ld a,(0e147h)		;6a7d   ; y si no hubo roce de red
	and a			;6a80
	jr nz,L_6A85		;6a81
	dec b			;6a83   ; se le restan dos mas: seis casos en total
	dec b			;6a84
L_6A85:
	ld hl,06a9ch		;6a85
	ld a,b			;6a88
	add a,a			;6a89   ; la tabla es de pares
	call suma_a_hl		;6a8a
	ld de,0e112h		;6a8d   ; (0xE112) y (0xE113): la velocidad con que sale la pelota
	ld a,(hl)			;6a90
	ld (de),a			;6a91
	inc hl			;6a92
	inc de			;6a93
	ld a,(hl)			;6a94
	ld (de),a			;6a95
	ld a,040h		;6a96
	ld (0e115h),a		;6a98   ; y (0xE115) a 0x40, que es la gravedad de este golpe
	ret			;6a9b

; ----------------------------------------------------------------------
; DATOS velocidades_del_golpe: 6 pares que 0x6A85 indexa con la direccion
;   sacada del mando; el par va a (0xE112), la velocidad de salida de la
;   pelota
;   0x6a9c..0x6aa8  (12 bytes)
DATA_velocidades_del_golpe:
	defb 004h,0a0h	; 6a9c
	defb 003h,0a0h	; 6a9e
	defb 004h,0a0h	; 6aa0
	defb 004h,000h	; 6aa2
	defb 006h,0d0h	; 6aa4
	defb 003h,090h	; 6aa6

; ----------------------------------------------------------------------
; DATOS alcance_del_golpe: 6 alcances y 6 valores hermanos, que 0x6A53 lee con
;   el mismo indice y con el indice mas seis
;   0x6aa8..0x6ab4  (12 bytes)
DATA_alcance_del_golpe:
	defb 00dh,010h,026h,027h,01dh,02ah	; 6aa8
	defb 060h,030h,066h,030h,050h,070h	; 6aae

; ======================================================================
; CODIGO 0x6ab4..0x6b8e  (218 bytes)
; ======================================================================



; ----------------------------------------------------------------------
; ===== La aritmetica de la pelota, en 16 bits =====
; ----------------------------------------------------------------------
resta_velocidad:		; resta el par de (HL) a la posicion de (DE), con el prestamo
	ld a,(de)			;6ab4
	sub (hl)			;6ab5
	ld (de),a			;6ab6
	jr nc,L_6ABE		;6ab7   ; el prestamo sube al byte alto
	dec de			;6ab9
	ld a,(de)			;6aba
	dec a			;6abb
	ld (de),a			;6abc
	inc de			;6abd
L_6ABE:
	dec de			;6abe
	dec hl			;6abf   ; y ahora el otro byte del par
	ld a,(de)			;6ac0
	sub (hl)			;6ac1
	ld (de),a			;6ac2
	ret			;6ac3
suma_velocidad:		; la misma cuenta sumando: la pelota avanza
	ld a,(de)			;6ac4
	add a,(hl)			;6ac5
	ld (de),a			;6ac6
	jr nc,L_6ACE		;6ac7   ; el acarreo sube al byte alto
	dec de			;6ac9
	ld a,(de)			;6aca
	inc a			;6acb
	ld (de),a			;6acc
	inc de			;6acd
L_6ACE:
	dec de			;6ace   ; el byte anterior de la posicion
	dec hl			;6acf   ; y el de la velocidad
	ld a,(de)			;6ad0   ; la posicion
	add a,(hl)			;6ad1   ; mas la velocidad
	ld (de),a			;6ad2   ; devuelta
	ret			;6ad3   ; hecho

; ----------------------------------------------------------------------
; ===== Dibujar la pelota, su sombra y sus reflejos =====
; ----------------------------------------------------------------------
dibuja_la_pelota:		; coloca los sprites de la pelota a partir de sus tres coordenadas
	ld hl,0e100h		;6ad4   ; las tres coordenadas de la pelota
	ld c,(hl)			;6ad7   ; la coordenada larga
	inc hl			;6ad8   ; la segunda
	inc hl			;6ad9
	ld b,(hl)			;6ada   ; la de a lo ancho
	inc hl			;6adb
	inc hl			;6adc
	ld a,(hl)			;6add   ; y la altura
	call proyecta		;6ade   ; que se convierten en fila y columna de la pantalla
	dec b			;6ae1
	dec b			;6ae2
	push bc			;6ae3
	ld a,c			;6ae4
	sub 010h		;6ae5   ; la pelota se dibuja 16 pixeles mas arriba de su punto
	ld c,a			;6ae7
	ld a,(0e117h)		;6ae8   ; (0xE117): sin sombra, el sprite se manda fuera
	and a			;6aeb
	jr z,L_6AF0		;6aec
	ld c,0e0h		;6aee
L_6AF0:
	ld a,b			;6af0
	cp 0fah		;6af1   ; y por los bordes tambien
	jr nc,L_6AF9		;6af3
	cp 004h		;6af5
	jr nc,L_6B00		;6af7
L_6AF9:
	ld a,00bh		;6af9
	ld (0e100h),a		;6afb   ; la pelota vuelve a 0x0B
	ld c,0e0h		;6afe
L_6B00:
	ld a,c			;6b00
	cp 0d0h		;6b01   ; 0xD0 es la fila prohibida del VDP: se esconde el sprite
	jr nz,L_6B07		;6b03
	ld c,0e0h		;6b05
L_6B07:
	ld hl,0e09ch		;6b07
	ld de,0e0b8h		;6b0a
	call coloca_dos_sprites		;6b0d
	ld hl,0e100h		;6b10
	ld c,(hl)			;6b13
	inc hl			;6b14
	inc hl			;6b15
	ld b,(hl)			;6b16
	ld a,(0e116h)		;6b17   ; (0xE116) trae el patron de la sombra
	cp 0aah		;6b1a   ; y si no vale 0xAA, no hay sombra que pintar
	jr nz,L_6B23		;6b1c
	ld bc,0e0e0h		;6b1e   ; las dos coordenadas, fuera de la pantalla
	jr L_6B26		;6b21
L_6B23:
	call proyecta_sin_altura		;6b23
L_6B26:
	ld a,c			;6b26   ; la fila que ha salido
	pop bc			;6b27   ; se recupera lo guardado
	ld c,a			;6b28   ; y la fila pasa a C
	ld hl,0e0a0h		;6b29   ; el otro par de sprites
	ld de,0e0bch		;6b2c   ; y su gemelo
	call coloca_dos_sprites		;6b2f   ; colocados

; ----------------------------------------------------------------------
; ===== El tamano de la pelota =====
; ----------------------------------------------------------------------
elige_el_tamano:		; cuanto mas alta y mas al fondo, mas pequena se dibuja
	ld a,(0e104h)		;6b32   ; la altura
	ld b,000h		;6b35   ; el byte alto de la cuenta
	cp 045h		;6b37   ; cuatro escalones: 0x45, 0x2F, 0x26 y 0x18
	jr nc,L_6B4D		;6b39   ; sin acarreo, ese
	inc b			;6b3b
	cp 02fh		;6b3c
	jr nc,L_6B4D		;6b3e
	inc b			;6b40
	cp 026h		;6b41
	jr nc,L_6B4D		;6b43
	inc b			;6b45
	cp 018h		;6b46
	jr nc,L_6B4D		;6b48
	inc b			;6b4a
	jr L_6B55		;6b4b
L_6B4D:
	ld a,(0e100h)		;6b4d   ; y pasado el medio campo, uno mas
	cp 069h		;6b50
	jr c,L_6B55		;6b52
	inc b			;6b54
L_6B55:
	ld a,b			;6b55
	ld (0e10fh),a		;6b56   ; (0xE10F) guarda el tamano elegido
	ld hl,06b8eh		;6b59   ; los cinco patrones de un lado
	call suma_a_hl		;6b5c
	ld a,(hl)			;6b5f
	ld c,a			;6b60
	ld a,b			;6b61
	ld hl,06b93h		;6b62   ; y los del otro
	call suma_a_hl		;6b65
	ld a,(hl)			;6b68
	ld b,a			;6b69
	ld hl,0e09eh		;6b6a
	ld de,0e0bah		;6b6d
	ld a,(0e100h)		;6b70   ; mas alla de 0xA1 se cambian los dos sprites de sitio
	cp 0a1h		;6b73
	jr c,L_6B78		;6b75
	ex de,hl			;6b77
L_6B78:
	ld (hl),c			;6b78   ; el patron del primero
	inc hl			;6b79
	inc hl			;6b7a
	inc hl			;6b7b
	inc hl			;6b7c
	ld (hl),b			;6b7d   ; y cuatro bytes mas alla, el del segundo
	ret			;6b7e
coloca_dos_sprites:		; pone fila y columna en un sprite y manda el otro fuera
	ld a,(0e100h)		;6b7f
	cp 0a1h		;6b82   ; cual de los dos se usa depende del lado de la mesa
	jr c,L_6B87		;6b84
	ex de,hl			;6b86
L_6B87:
	ld (hl),c			;6b87
	inc hl			;6b88
	ld (hl),b			;6b89
	ld a,0e0h		;6b8a   ; y al que no toca, 0xE0: fuera de la pantalla
	ld (de),a			;6b8c
	ret			;6b8d

; ----------------------------------------------------------------------
; DATOS pelota_de_cerca: los patrones 0x38, 0x34, 0x30, 0x2C y 0x28: la pelota
;   en su mitad de la mesa
;   0x6b8e..0x6b93  (5 bytes)
DATA_pelota_de_cerca:
	defb 038h	; 6b8e
	defb 034h	; 6b8f
	defb 030h	; 6b90
	defb 02ch	; 6b91
	defb 028h	; 6b92

; ----------------------------------------------------------------------
; DATOS pelota_de_lejos: los patrones 0x4C a 0x3C, los mismos cinco tamanos
;   para la otra mitad
;   0x6b93..0x6b98  (5 bytes)
DATA_pelota_de_lejos:
	defb 04ch	; 6b93
	defb 048h	; 6b94
	defb 044h	; 6b95
	defb 040h	; 6b96
	defb 03ch	; 6b97

; ======================================================================
; CODIGO 0x6b98..0x6d15  (381 bytes)
; ======================================================================


proyecta_sin_altura:		; la misma proyeccion dando la altura por sabida
	ld (0e122h),bc		;6b98
	ld (0e124h),a		;6b9c
	jr L_6BE5		;6b9f

; ----------------------------------------------------------------------
; ===== LA PERSPECTIVA =====
; ----------------------------------------------------------------------
proyecta:		; convierte las tres coordenadas de la mesa en fila y columna de pantalla
	ld (0e122h),bc		;6ba1   ; la coordenada larga y la ancha
	ld (0e124h),a		;6ba5   ; y la altura
	ld a,(0e122h)		;6ba8
	ld h,a			;6bab
	ld e,0d4h		;6bac   ; 0xD4: el factor de la profundidad
	call multiplica_8x8		;6bae
	ld a,h			;6bb1
	add a,077h		;6bb2   ; 0x77 es el desplazamiento del horizonte
	ld c,a			;6bb4
	ld b,000h		;6bb5
	jr nc,L_6BBA		;6bb7
	inc b			;6bb9
L_6BBA:
	push bc			;6bba
	ld a,(0e123h)		;6bbb   ; la coordenada a lo ancho
	sub 080h		;6bbe   ; medida desde el centro de la mesa
	ld b,000h		;6bc0
	jr nc,L_6BC8		;6bc2
	neg		;6bc4   ; con el signo aparte
	ld b,001h		;6bc6
L_6BC8:
	add a,a			;6bc8
	ld h,a			;6bc9
	ld a,b			;6bca
	ld (0e121h),a		;6bcb   ; (0xE121) guarda de que lado cae
	ld e,0bfh		;6bce   ; 0xBF: el factor de la anchura, que se estrecha con la distancia
	call multiplica_8x8		;6bd0
	pop bc			;6bd3
	ex de,hl			;6bd4
	call divide		;6bd5   ; y el producto de los dos
	ld a,(0e121h)		;6bd8
	and a			;6bdb
	ld a,080h		;6bdc   ; 0x80 es el centro de la pantalla
	jr nz,L_6BE3		;6bde
	add a,e			;6be0   ; al que se le suma o se le resta lo que se haya abierto
	jr L_6BE4		;6be1
L_6BE3:
	sub e			;6be3
L_6BE4:
	ld b,a			;6be4
L_6BE5:
	push bc			;6be5   ; la columna, que hace falta al final
	ld a,(0e122h)		;6be6   ; la coordenada larga
	ld h,a			;6be9   ; al multiplicando
	ld e,08eh		;6bea   ; 0x8E: el factor de la fila
	call multiplica_8x8		;6bec   ; por 0x8E: cuanto sube la fila con la distancia
	push hl			;6bef   ; el producto, guardado
	ld a,(0e124h)		;6bf0   ; la altura
	ld h,a			;6bf3   ; al multiplicando
	ld e,0d4h		;6bf4   ; y 0xD4 otra vez, ahora sobre la altura
	call multiplica_8x8		;6bf6   ; por 0xD4, el mismo factor de la profundidad
	ld a,h			;6bf9   ; solo el byte alto
	pop hl			;6bfa   ; y se recupera el otro producto
	add a,h			;6bfb   ; las dos aportaciones se suman: la profundidad sube la pelota y la altura tambien
	jr c,L_6C4E		;6bfc   ; si se desborda, la pelota se sale de la pantalla
	ld h,a			;6bfe   ; la suma de los dos
	ld a,0b2h		;6bff   ; 0xB2: la fila del horizonte
	sub h			;6c01   ; menos lo que haya subido
	jr c,L_6C4E		;6c02   ; y si se pasa, fuera
	ld e,a			;6c04   ; la fila que queda
	ld h,0bfh		;6c05   ; 0xBF: el factor de la anchura
	call multiplica_8x8		;6c07   ; y se multiplican
	push hl			;6c0a   ; el resultado, guardado
	ld a,(0e122h)		;6c0b   ; la coordenada larga otra vez
	ld h,a			;6c0e   ; al multiplicando
	ld e,0d4h		;6c0f   ; y por el factor de la profundidad
	call multiplica_8x8		;6c11   ; multiplicados
	ld a,h			;6c14   ; el byte alto
	push af			;6c15   ; guardado
	ld a,(0e124h)		;6c16   ; la altura
	ld h,a			;6c19   ; al multiplicando
	ld e,08eh		;6c1a   ; por el factor de la fila
	call multiplica_8x8		;6c1c   ; multiplicados
	pop af			;6c1f   ; se recupera el otro
	add a,077h		;6c20   ; mas 0x77, el desplazamiento del horizonte
	ld d,000h		;6c22   ; el byte alto, a cero
	ld e,a			;6c24   ; y el bajo, el resultado
	jr nc,L_6C28		;6c25   ; sin acarreo, ahi se queda
	inc d			;6c27   ; y con el, sube el alto
L_6C28:
	push de			;6c28   ; el par, guardado
	ld a,e			;6c29   ; su byte bajo
	sub h			;6c2a   ; menos la aportacion de la altura
	ld c,a			;6c2b   ; la fila que sale
	jr nc,L_6C2F		;6c2c   ; y si no hubo prestamo, esa
	dec d			;6c2e
L_6C2F:
	ld b,d			;6c2f   ; el resto
	pop de			;6c30   ; se recupera el dividendo
	rl h		;6c31   ; con su bit de arriba
	ld a,e			;6c33   ; el byte bajo
	sub h			;6c34   ; menos el resto
	ld e,a			;6c35   ; devuelto
	jr nc,L_6C39		;6c36   ; sin prestamo, ya esta
	dec d			;6c38   ; y con el, baja el alto
L_6C39:
	rr d		;6c39   ; el par, desplazado
	rr e		;6c3b   ; un bit a la derecha: dividido entre dos
	ld a,e			;6c3d   ; el byte bajo
	ld (0e125h),a		;6c3e   ; guardado
	pop de			;6c41   ; se recupera el dividendo
	call divide		;6c42   ; y se divide
	ld a,d			;6c45   ; el byte alto del cociente
	and a			;6c46   ; a cero cabe en un byte
	ld a,e			;6c47   ; el bajo
	jr nz,L_6C4E		;6c48   ; y si no cabe, la pelota se sale
	sub 010h		;6c4a   ; menos 0x10: la mitad del sprite
	jr L_6C50		;6c4c   ; y a rematar
L_6C4E:
	ld a,0f0h		;6c4e   ; 0xF0: fuera de la pantalla
L_6C50:
	pop bc			;6c50   ; se recupera la columna
	ld c,a			;6c51   ; y la fila que sale
	ret			;6c52   ; hecho

; ----------------------------------------------------------------------
; ===== El bote en la mesa =====
; ----------------------------------------------------------------------
L_6C53:
	ld (0e104h),a		;6c53   ; la altura del bote
	ld hl,0e114h		;6c56
	inc (hl)			;6c59   ; y una fase mas del intercambio
	ld a,(hl)			;6c5a
	cp 002h		;6c5b   ; en la 2 se anota que hubo bote
	jr nz,L_6C67		;6c5d
	dec a			;6c5f
	ld (0e147h),a		;6c60
	ld a,c			;6c63
	ld (0e142h),a		;6c64
L_6C67:
	ld hl,0e10bh		;6c67
	ld a,(hl)			;6c6a
	sub b			;6c6b   ; la velocidad de subida pierde B: la pelota bota cada vez mas bajo
	ld (hl),a			;6c6c
	jr nc,L_6C7A		;6c6d
	dec hl			;6c6f
	ld a,(hl)			;6c70
	sub 001h		;6c71   ; el prestamo, al byte alto
	ld (hl),a			;6c73
	jr nc,L_6C7A		;6c74
	xor a			;6c76   ; y al agotarse, se queda a cero
	ld (hl),a			;6c77
	inc hl			;6c78
	ld (hl),a			;6c79
L_6C7A:
	ld a,(0e114h)		;6c7a
	cp 002h		;6c7d
	jr nz,L_6CC6		;6c7f
	ld c,069h		;6c81   ; la linea de la red: 0x69 por un lado
	ld a,(0e10ch)		;6c83
	and a			;6c86
	jr z,L_6C8B		;6c87
	ld c,05fh		;6c89   ; y 0x5F por el otro
L_6C8B:
	ld a,(0e100h)		;6c8b
	cp c			;6c8e   ; (0xE146) anota en que campo boto
	ld a,001h		;6c8f
	jr nc,L_6C94		;6c91
	dec a			;6c93
L_6C94:
	ld (0e146h),a		;6c94
	ld a,(0e144h)		;6c97
	ld hl,0e146h		;6c9a
	xor (hl)			;6c9d   ; y comparado con el campo de quien golpeo
	ld b,000h		;6c9e
	jr nz,L_6CA3		;6ca0
	inc b			;6ca2
L_6CA3:
	ld a,(0e141h)		;6ca3   ; (0xE141): de quien fue
	and a			;6ca6
	ld a,b			;6ca7
	jr z,L_6CAC		;6ca8
	xor 001h		;6caa
L_6CAC:
	ld (0e14ch),a		;6cac   ; (0xE14C) queda a uno si el bote cayo donde no debia: la falta
	and a			;6caf
	jr z,L_6CC6		;6cb0
	ld hl,0e106h		;6cb2
	ld a,(hl)			;6cb5
	cp 006h		;6cb6
	jr c,L_6CBC		;6cb8
	sub 003h		;6cba
L_6CBC:
	ld (hl),a			;6cbc   ; guardado
	ld hl,0e10ah		;6cbd   ; la velocidad de subida
	xor a			;6cc0   ; cero
	ld (hl),a			;6cc1   ; en su byte alto
	inc hl			;6cc2   ; y el bajo
	ld a,0f0h		;6cc3   ; 0xF0: la pelota sale rebotada
	ld (hl),a			;6cc5   ; guardado
L_6CC6:
	xor a			;6cc6   ; cero
	ld (0e10eh),a		;6cc7
	jp frena_la_pelota		;6cca
L_6CCD:
	ld a,(0e114h)		;6ccd   ; la fase del intercambio
	dec a			;6cd0   ; solo en la 1
	ret nz			;6cd1   ; y en las demas, nada
	ld a,(0e111h)		;6cd2   ; (0xE111), el frenado
	and a			;6cd5   ; a cero
	ret z			;6cd6   ; no hay nada que corregir
	ld hl,0e10bh		;6cd7   ; la velocidad de subida
	ld a,(0e110h)		;6cda   ; la clase de golpe
	and a			;6cdd   ; a cero
	jr nz,L_6CE8		;6cde   ; y si no, por el otro camino
	ld a,080h		;6ce0   ; 0x80, medio escalon
	add a,(hl)			;6ce2   ; sumado a la velocidad
	ld (hl),a			;6ce3   ; y devuelto
	ret nc			;6ce4   ; sin acarreo, ya esta
	dec hl			;6ce5   ; y con el, al byte alto
	inc (hl)			;6ce6   ; que sube uno
	ret			;6ce7   ; hecho
L_6CE8:
	dec hl			;6ce8   ; el byte alto
	ld a,(hl)			;6ce9   ; leido
	and a			;6cea   ; y mirado
	ret z			;6ceb
	inc hl			;6cec
	ld a,(hl)			;6ced
	sub 010h		;6cee
	ld (hl),a			;6cf0
	ret nc			;6cf1
	dec hl			;6cf2
	dec (hl)			;6cf3
	ret			;6cf4
L_6CF5:
	ld de,06d1dh		;6cf5
	jp pinta_rotulo		;6cf8
L_6CFB:
	ld hl,06d15h		;6cfb   ; la tabla de los cuatro guiones laterales
	ld a,(0e14bh)		;6cfe   ; (0xE14B), de que lado cayo el punto
	add a,a			;6d01   ; doblado
	add a,a			;6d02   ; y otra vez: cuatro bytes por lado
	call suma_a_hl		;6d03   ; sumado a la tabla
	ld a,(0e003h)		;6d06   ; el reloj
	bit 2,a		;6d09   ; el bit 2, que cambia dieciseis veces por segundo
	jr z,L_6D0F		;6d0b   ; con el apagado, el primer guion del par
	inc hl			;6d0d   ; y con el puesto
	inc hl			;6d0e   ; el segundo: eso es lo que hace PARPADEAR la columna
L_6D0F:
	ld e,(hl)			;6d0f   ; la entrada
	inc hl			;6d10   ; el byte siguiente
	ld d,(hl)			;6d11   ; y su byte alto
	jp pinta_rotulo		;6d12

; ----------------------------------------------------------------------
; DATOS tabla_de_guiones_laterales: 4 entradas: 0x6D75, 0x6DA1, 0x6DB1 y
;   0x6DDD. La lee 0x6D0F antes de saltar al interprete
;   0x6d15..0x6d1d  (8 bytes)
DATA_tabla_de_guiones_laterales:
	defw 06d75h,06da1h,06db1h,06dddh	; 6d15  -> DATA_guion_lateral_derecho DATA_guion_lateral_derecho_corto DATA_guion_lateral_izquierdo DATA_guion_lateral_izquierdo_corto

; ----------------------------------------------------------------------
; DATOS guion_lateral_completo: 16 destinos: las dos columnas enteras, la
;   izquierda desde 0x3801 y la derecha desde 0x381B
;   0x6d1d..0x6d75  (88 bytes)
DATA_guion_lateral_completo:
	defb 001h,038h,0a9h,0aah,0a9h,0adh,0feh,021h,038h,0abh,0ach,0abh,0feh,040h,038h,0a9h	; 6d1d  .8.....!8....@8.
	defb 0aah,0a9h,0adh,0feh,060h,038h,0abh,0ach,0abh,0feh,081h,038h,0a9h,05ah,0feh,0a1h	; 6d2d  ....`8.....8.Z..
	defb 038h,0abh,0feh,0c0h,038h,0a9h,0b4h,0feh,0e0h,038h,0b5h,0feh,01bh,038h,04dh,049h	; 6d3d  8...8....8...8MI
	defb 04ah,049h,0feh,03ch,038h,04bh,04ch,04bh,0feh,05ch,038h,04dh,04eh,04fh,049h,0feh	; 6d4d  JI.<8KLK.\8MNOI.
	defb 07dh,038h,050h,051h,04bh,0feh,09dh,038h,052h,053h,0feh,0beh,038h,04bh,0feh,0deh	; 6d5d  }8PQK..8RS..8K..
	defb 038h,054h,049h,0feh,0ffh,038h,055h,0ffh	; 6d6d  8TI..8U.

; ----------------------------------------------------------------------
; DATOS guion_lateral_derecho: 8 destinos, solo la columna de 0x381B
;   0x6d75..0x6da1  (44 bytes)
DATA_guion_lateral_derecho:
	defb 01bh,038h,0e0h,0dbh,04ah,0dbh,0feh,03ch,038h,0dch,04ch,0dch,0feh,05ch,038h,0e0h	; 6d75  .8..J..<8.L..\8.
	defb 04eh,04fh,0dbh,0feh,07dh,038h,07dh,051h,0dch,0feh,09dh,038h,083h,07fh,0feh,0beh	; 6d85  NO..}8}Q...8....
	defb 038h,0dch,0feh,0deh,038h,0e2h,0dbh,0feh,0ffh,038h,0deh,0ffh	; 6d95  8...8....8..

; ----------------------------------------------------------------------
; DATOS guion_lateral_derecho_corto: 4 destinos de un solo patron cada uno
;   0x6da1..0x6db1  (16 bytes)
DATA_guion_lateral_derecho_corto:
	defb 01bh,038h,0e4h,0feh,05ch,038h,0e4h,0feh,09dh,038h,087h,0feh,0deh,038h,0e6h,0ffh	; 6da1  .8..\8...8...8..

; ----------------------------------------------------------------------
; DATOS guion_lateral_izquierdo: 8 destinos, solo la columna de 0x3801
;   0x6db1..0x6ddd  (44 bytes)
DATA_guion_lateral_izquierdo:
	defb 001h,038h,07bh,0aah,07bh,080h,0feh,021h,038h,07ch,0ach,07ch,0feh,040h,038h,07bh	; 6db1  .8{.{..!8|.|.@8{
	defb 0aah,07bh,080h,0feh,060h,038h,07ch,0ach,07ch,0feh,081h,038h,07bh,081h,0feh,0a1h	; 6dc1  .{..`8|.|..8{...
	defb 038h,07ch,0feh,0c0h,038h,07bh,082h,0feh,0e0h,038h,07eh,0ffh	; 6dd1  8|..8{...8~.

; ----------------------------------------------------------------------
; DATOS guion_lateral_izquierdo_corto: 4 destinos de un solo patron cada uno
;   0x6ddd..0x6ded  (16 bytes)
DATA_guion_lateral_izquierdo_corto:
	defb 004h,038h,084h,0feh,043h,038h,084h,0feh,082h,038h,085h,0feh,0c1h,038h,086h,0ffh	; 6ddd  .8..C8...8...8..

; ======================================================================
; CODIGO 0x6ded..0x6e0e  (33 bytes)
; ======================================================================


L_6DED:
	ld a,(0e003h)		;6ded   ; el reloj
	bit 2,a		;6df0   ; el bit 2: dieciseis veces por segundo
	jp z,L_444F		;6df2   ; con el apagado, el marcador entero
	ld hl,039dch		;6df5   ; el sitio del tanteo de un lado
	ld a,(0e14bh)		;6df8   ; de quien es el punto
	and a			;6dfb   ; a cero
	jr z,L_6E01		;6dfc   ; ese
	ld hl,039c3h		;6dfe   ; y si no, el del otro
L_6E01:
	xor a			;6e01   ; cero: se borra
	ld bc,00002h		;6e02   ; los dos digitos: el tanteo del que ha ganado PARPADEA
	jp 00056h		;6e05   ; BIOS FILVRM - Fills VRAM with value
L_6E08:
	ld de,06e0eh		;6e08   ; el guion de CHANGE COURT
	jp pinta_rotulo		;6e0b

; ----------------------------------------------------------------------
; DATOS guion_change_court: "CHANGE COURT" en 0x398A
;   0x6e0e..0x6e1d  (15 bytes)
DATA_guion_change_court:
	defb 08ah,039h,023h,028h,021h,02eh,027h,025h,000h,023h,02fh,035h,032h,034h,0ffh	; 6e0e  .9#(!.'%.#/524.

; ======================================================================
; CODIGO 0x6e1d..0x6ead  (144 bytes)
; ======================================================================


L_6E1D:
	ld hl,0e10ch		;6e1d
	ld a,(hl)			;6e20
	cpl			;6e21
	ld (hl),a			;6e22
L_6E23:
	ld a,(0e150h)		;6e23   ; el alcance del golpe
	ld b,a			;6e26   ; guardado
	ld de,0e152h		;6e27   ; donde van los factores
	call L_6EA3		;6e2a   ; por la curva que baja
	ld a,b			;6e2d   ; el alcance otra vez
	call L_6E99		;6e2e   ; y por la que sube
	ld a,(0e151h)		;6e31   ; el efecto que ha salido
	ld b,a			;6e34   ; guardado
	cp 01fh		;6e35   ; por debajo de 0x1F
	ld a,000h		;6e37   ; cero
	jr c,L_6E3C		;6e39   ; y ese se queda
	inc a			;6e3b   ; y si no, uno: el lado hacia el que sale cambia
L_6E3C:
	ld (0e10dh),a		;6e3c   ; (0xE10D): hacia que lado sale la pelota
	ld a,b			;6e3f   ; el efecto
	call L_6E99		;6e40   ; por la curva que sube
	ld a,b			;6e43   ; y otra vez
	call L_6EA3		;6e44   ; por la que baja
	ld a,(0e153h)		;6e47   ; uno de los factores del efecto
	ld h,a			;6e4a   ; al multiplicando
	push hl			;6e4b   ; guardado, que hace falta dos veces
	ld a,(0e155h)		;6e4c   ; y el otro
	ld e,a			;6e4f   ; al multiplicador
	call multiplica_8x8		;6e50   ; multiplicados
	ld a,h			;6e53   ; solo el byte alto
	ld (0e156h),a		;6e54   ; a su sitio
	pop hl			;6e57   ; se recupera el multiplicando
	ld a,(0e154h)		;6e58   ; y el otro factor
	ld e,a			;6e5b   ; al multiplicador
	call multiplica_8x8		;6e5c   ; multiplicados
	ld a,h			;6e5f   ; el byte alto
	ld (0e157h),a		;6e60   ; a su sitio
	ld bc,(0e112h)		;6e63   ; la velocidad de salida
	ld a,(0e152h)		;6e67   ; por el factor del golpe
	call multiplica_16x8		;6e6a   ; multiplicados a 16 bits
	ld (0e10ah),hl		;6e6d   ; y a la velocidad de subida de la pelota
	ld a,(0e150h)		;6e70   ; el alcance del golpe
	cp 01eh		;6e73   ; por debajo de 0x1E el golpe es corto
	ld a,000h		;6e75   ; cero
	jr nc,L_6E7B		;6e77   ; y con alcance largo, ese
	ld a,001h		;6e79   ; uno: la pelota arranca CAYENDO
L_6E7B:
	ld (0e10eh),a		;6e7b   ; y se anota
	ld bc,(0e112h)		;6e7e   ; la velocidad otra vez
	ld a,(0e156h)		;6e82
	call multiplica_16x8		;6e85
	ld (0e108h),hl		;6e88
	ld bc,(0e112h)		;6e8b
	ld a,(0e157h)		;6e8f
	call multiplica_16x8		;6e92
	ld (0e106h),hl		;6e95
	ret			;6e98
L_6E99:
	ld hl,06eadh		;6e99   ; la tabla de seno, desde su principio
	call suma_a_hl		;6e9c   ; mas el indice
	ld a,(hl)			;6e9f   ; el valor
	ld (de),a			;6ea0   ; al destino
	inc de			;6ea1   ; que avanza
	ret			;6ea2   ; hecho
L_6EA3:
	ld hl,06ecch		;6ea3   ; la misma tabla 31 posiciones mas alla: un cuarto de onda, o sea el coseno
	call suma_a_hl		;6ea6   ; mas el indice
	ld a,(hl)			;6ea9   ; el valor
	ld (de),a			;6eaa   ; al destino
	inc de			;6eab   ; que avanza
	ret			;6eac   ; hecho

; ----------------------------------------------------------------------
; DATOS tabla_de_seno: 92 bytes: 31 valores subiendo de 12 a 255, 30 bajando,
;   un cero, y 30 subiendo otra vez. 0x6E99 la lee desde 0x6EAD y 0x6EA3 desde
;   0x6ECC, un cuarto de onda mas alla
;   0x6ead..0x6f09  (92 bytes)
DATA_tabla_de_seno:
	defb 00ch	; 6ead
	defb 019h	; 6eae
	defb 025h	; 6eaf
	defb 031h	; 6eb0
	defb 03eh	; 6eb1
	defb 04ah	; 6eb2
	defb 056h	; 6eb3
	defb 061h	; 6eb4
	defb 06dh	; 6eb5
	defb 078h	; 6eb6
	defb 083h	; 6eb7
	defb 08eh	; 6eb8
	defb 098h	; 6eb9
	defb 0a2h	; 6eba
	defb 0abh	; 6ebb
	defb 0b5h	; 6ebc
	defb 0bdh	; 6ebd
	defb 0c5h	; 6ebe
	defb 0cdh	; 6ebf
	defb 0d4h	; 6ec0
	defb 0dbh	; 6ec1
	defb 0e1h	; 6ec2
	defb 0e7h	; 6ec3
	defb 0ech	; 6ec4
	defb 0f1h	; 6ec5
	defb 0f4h	; 6ec6
	defb 0fbh	; 6ec7
	defb 0fdh	; 6ec8
	defb 0feh	; 6ec9
	defb 0ffh	; 6eca
	defb 0ffh	; 6ecb
	defb 0ffh	; 6ecc
	defb 0feh	; 6ecd
	defb 0fdh	; 6ece
	defb 0fbh	; 6ecf
	defb 0f4h	; 6ed0
	defb 0f1h	; 6ed1
	defb 0ech	; 6ed2
	defb 0e7h	; 6ed3
	defb 0e1h	; 6ed4
	defb 0dbh	; 6ed5
	defb 0d4h	; 6ed6
	defb 0cdh	; 6ed7
	defb 0c5h	; 6ed8
	defb 0bdh	; 6ed9
	defb 0b5h	; 6eda
	defb 0abh	; 6edb
	defb 0a2h	; 6edc
	defb 098h	; 6edd
	defb 08eh	; 6ede
	defb 083h	; 6edf
	defb 078h	; 6ee0
	defb 06dh	; 6ee1
	defb 061h	; 6ee2
	defb 056h	; 6ee3
	defb 04ah	; 6ee4
	defb 03eh	; 6ee5
	defb 031h	; 6ee6
	defb 025h	; 6ee7
	defb 019h	; 6ee8
	defb 00ch	; 6ee9
	defb 000h	; 6eea
	defb 00ch	; 6eeb
	defb 019h	; 6eec
	defb 025h	; 6eed
	defb 031h	; 6eee
	defb 03eh	; 6eef
	defb 04ah	; 6ef0
	defb 056h	; 6ef1
	defb 061h	; 6ef2
	defb 06dh	; 6ef3
	defb 078h	; 6ef4
	defb 083h	; 6ef5
	defb 08eh	; 6ef6
	defb 098h	; 6ef7
	defb 0a2h	; 6ef8
	defb 0abh	; 6ef9
	defb 0b5h	; 6efa
	defb 0bdh	; 6efb
	defb 0c5h	; 6efc
	defb 0cdh	; 6efd
	defb 0d4h	; 6efe
	defb 0dbh	; 6eff
	defb 0e1h	; 6f00
	defb 0e7h	; 6f01
	defb 0ech	; 6f02
	defb 0f1h	; 6f03
	defb 0f4h	; 6f04
	defb 0fbh	; 6f05
	defb 0fdh	; 6f06
	defb 0feh	; 6f07
	defb 0ffh	; 6f08

; ======================================================================
; CODIGO 0x6f09..0x6f11  (8 bytes)
; ======================================================================


saca_el_efecto:		; toma de la curva el valor que toque y lo deja en (0xE151)
	call suma_a_hl		;6f09
	ld a,(hl)			;6f0c
	ld (0e151h),a		;6f0d
	ret			;6f10

; ----------------------------------------------------------------------
; DATOS alturas_que_suben: 18 valores de 0x19 a 0x24, que se aplanan al final.
;   Los leen 0x659F y 0x65CB
;   0x6f11..0x6f23  (18 bytes)
DATA_alturas_que_suben:
	defb 019h	; 6f11
	defb 01ah	; 6f12
	defb 01ch	; 6f13
	defb 01dh	; 6f14
	defb 01eh	; 6f15
	defb 01eh	; 6f16
	defb 021h	; 6f17
	defb 022h	; 6f18
	defb 023h	; 6f19
	defb 023h	; 6f1a
	defb 024h	; 6f1b
	defb 024h	; 6f1c
	defb 024h	; 6f1d
	defb 024h	; 6f1e
	defb 024h	; 6f1f
	defb 024h	; 6f20
	defb 024h	; 6f21
	defb 024h	; 6f22

; ----------------------------------------------------------------------
; DATOS alturas_que_bajan: 18 valores de 0x23 a 0x18, la simetrica de la
;   anterior. Los leen 0x65A9 y 0x65D5
;   0x6f23..0x6f35  (18 bytes)
DATA_alturas_que_bajan:
	defb 023h	; 6f23
	defb 022h	; 6f24
	defb 020h	; 6f25
	defb 01fh	; 6f26
	defb 01eh	; 6f27
	defb 01eh	; 6f28
	defb 01bh	; 6f29
	defb 01ah	; 6f2a
	defb 019h	; 6f2b
	defb 019h	; 6f2c
	defb 018h	; 6f2d
	defb 018h	; 6f2e
	defb 018h	; 6f2f
	defb 018h	; 6f30
	defb 018h	; 6f31
	defb 018h	; 6f32
	defb 018h	; 6f33
	defb 018h	; 6f34

; ======================================================================
; CODIGO 0x6f35..0x6f5d  (40 bytes)
; ======================================================================


efecto_por_el_centro:		; el efecto sale de lo lejos del centro que pase la pelota
	ld b,000h		;6f35
	ld a,(0e102h)		;6f37   ; la coordenada a lo ancho
	sub 080h		;6f3a   ; medida desde el centro de la mesa
	jr nc,L_6F42		;6f3c
	neg		;6f3e   ; con el signo aparte, que cambia el tramo de la tabla
	ld b,004h		;6f40
L_6F42:
	cp 020h		;6f42   ; tres escalones: 0x20, 0x10 y 0x08
	jr c,L_6F47		;6f44
	inc b			;6f46
L_6F47:
	cp 010h		;6f47
	jr c,L_6F4C		;6f49
	inc b			;6f4b
L_6F4C:
	cp 008h		;6f4c
	jr c,L_6F51		;6f4e
	inc b			;6f50
L_6F51:
	ld hl,06f5dh		;6f51   ; y de ahi sale el efecto
	ld a,b			;6f54
	call suma_a_hl		;6f55
	ld a,(hl)			;6f58
	ld (0e151h),a		;6f59
	ret			;6f5c

; ----------------------------------------------------------------------
; DATOS pasos_de_la_pelota: 8 bytes que lee 0x6F51
;   0x6f5d..0x6f65  (8 bytes)
DATA_pasos_de_la_pelota:
	defb 01eh	; 6f5d
	defb 020h	; 6f5e
	defb 022h	; 6f5f
	defb 024h	; 6f60
	defb 01eh	; 6f61
	defb 01ch	; 6f62
	defb 01ah	; 6f63
	defb 018h	; 6f64

; ======================================================================
; CODIGO 0x6f65..0x70f0  (395 bytes)
; ======================================================================



; ----------------------------------------------------------------------
; ===== Multiplicar y dividir, que el Z80 no sabe =====
; ----------------------------------------------------------------------
multiplica_8x8:		; HL = H por E, sumando y desplazando ocho veces
	ld l,000h		;6f65
	ld d,l			;6f67
	ld b,008h		;6f68   ; ocho bits, un paso por bit
L_6F6A:
	add hl,hl			;6f6a   ; desplaza el resultado
	jr nc,L_6F6E		;6f6b
	add hl,de			;6f6d   ; y suma el multiplicando cuando el bit sale a uno
L_6F6E:
	djnz L_6F6A		;6f6e
	ret			;6f70
multiplica_16x8:		; la anterior aplicada a las dos mitades, y sumadas con acarreo
	ld h,b			;6f71
	ld e,a			;6f72
	push bc			;6f73
	push de			;6f74
	call multiplica_8x8		;6f75   ; la parte baja
	pop de			;6f78
	pop bc			;6f79
	push hl			;6f7a
	ld h,c			;6f7b
	call multiplica_8x8		;6f7c   ; y la alta
	pop bc			;6f7f
	ld a,b			;6f80
	add a,l			;6f81   ; se juntan por el byte que comparten
	jr nc,L_6F85		;6f82
	inc h			;6f84
L_6F85:
	ld l,h			;6f85
	ld h,a			;6f86
	ret			;6f87
divide:		; divide DE entre BC dejando el cociente en E, por restas y desplazamientos
	ld hl,00000h		;6f88
	exx			;6f8b
	ld b,010h		;6f8c   ; dieciseis pasos, uno por bit
L_6F8E:
	exx			;6f8e
	sla e		;6f8f   ; el dividendo entra por arriba
	rl d		;6f91
	adc hl,hl		;6f93
	sbc hl,bc		;6f95   ; se intenta restar el divisor
	jr c,L_6F9C		;6f97   ; si no cabe, se deshace la resta
	inc e			;6f99   ; y si cabe, un uno en el cociente
	jr L_6F9D		;6f9a
L_6F9C:
	add hl,bc			;6f9c
L_6F9D:
	exx			;6f9d
	djnz L_6F8E		;6f9e
	exx			;6fa0
	ret			;6fa1

; ----------------------------------------------------------------------
; ===== El rozamiento =====
; ----------------------------------------------------------------------
frena_la_pelota:		; aplica (0xE111) a las tres velocidades, restando o sumando
	ld hl,0e111h		;6fa2
	ld a,(hl)			;6fa5   ; (0xE111) es cuanto frena
	and a			;6fa6
	ret z			;6fa7   ; a cero, la pelota no pierde nada
	push af			;6fa8
	rra			;6fa9   ; a la cuarta parte, y se guarda para el cuadro siguiente
	rra			;6faa
	ld (hl),a			;6fab
	ld a,(0e110h)		;6fac   ; (0xE110) es la clase de golpe, y decide si frena o EMPUJA
	and a			;6faf
	jr nz,L_6FD6		;6fb0
	pop af			;6fb2
	push af			;6fb3
	ld bc,(0e106h)		;6fb4   ; las tres velocidades, una a una
	call L_6FFA		;6fb8
	ld (0e106h),hl		;6fbb
	pop af			;6fbe
	push af			;6fbf
	ld bc,(0e108h)		;6fc0
	call L_6FFA		;6fc4
	ld (0e108h),hl		;6fc7
	pop af			;6fca
	ld bc,(0e10ah)		;6fcb
	call L_7009		;6fcf
	ld (0e10ah),hl		;6fd2
	ret			;6fd5
L_6FD6:
	pop af			;6fd6   ; y con el otro golpe, las mismas tres al reves
	push af			;6fd7   ; el frenado, que hace falta tres veces
	ld bc,(0e106h)		;6fd8   ; la primera velocidad
	call L_7009		;6fdc   ; y aqui se le SUMA en vez de restarsele
	ld (0e106h),hl		;6fdf   ; devuelta
	pop af			;6fe2   ; el frenado
	push af			;6fe3   ; guardado otra vez
	ld bc,(0e108h)		;6fe4   ; la segunda velocidad
	call L_7009		;6fe8   ; sumada
	ld (0e108h),hl		;6feb   ; devuelta
	pop af			;6fee   ; y el frenado por ultima vez
	ld bc,(0e10ah)		;6fef   ; la tercera velocidad
	call L_6FFA		;6ff3   ; esta con el otro signo
	ld (0e10ah),hl		;6ff6   ; devuelta
	ret			;6ff9   ; hecho
L_6FFA:
	push bc			;6ffa   ; la cuenta
	call multiplica_16x8		;6ffb   ; multiplicados a 16 bits
	pop bc			;6ffe   ; se recupera
	ld a,b			;6fff   ; su byte alto
	add a,h			;7000   ; mas el del producto
	ld h,a			;7001   ; devuelto
	jr nc,L_7005		;7002   ; sin acarreo, ya esta
	inc l			;7004   ; y con el, sube el bajo
L_7005:
	ld a,c			;7005   ; el byte bajo
	add a,l			;7006   ; mas el del producto
	ld l,a			;7007   ; devuelto
	ret			;7008   ; hecho
L_7009:
	push bc			;7009   ; la cuenta
	call multiplica_16x8		;700a   ; multiplicados
	pop bc			;700d   ; y se recupera
	ld a,b			;700e
	sub h			;700f
	ld h,a			;7010
	jr nc,L_7014		;7011
	dec c			;7013
L_7014:
	ld a,c			;7014
	sub l			;7015
	ld l,a			;7016
	ret			;7017

; ----------------------------------------------------------------------
; ===== MONTAR LA PISTA =====
; ----------------------------------------------------------------------
monta_la_pista:		; el color, los patrones, el espejo y la red
	ld hl,00200h		;7018   ; el color de la pista, a 0x0200
	ld de,0733ah		;701b
	call descomprime_tres_tercios		;701e
	ld hl,00500h		;7021
	ld de,0733ah		;7024   ; y el mismo bloque otra vez a 0x0500: dos bandas de color
	call descomprime_tres_tercios		;7027
	ld hl,02200h		;702a
	ld de,070f0h		;702d   ; los patrones de la pista, 93 tiles en los tres tercios
	call descomprime_tres_tercios		;7030
	ld hl,02a00h		;7033   ; y ahora el espejo: origen 0x2A00
	ld de,02500h		;7036   ; destino 0x2500
	ld b,003h		;7039
L_703B:
	push bc			;703b
	push hl			;703c
	push de			;703d
	ld bc,00300h		;703e   ; 0x300 bytes, o sea 96 tiles
	call copia_reflejando		;7041   ; copiar dando la vuelta a cada byte
	pop de			;7044
	ld hl,00800h		;7045   ; solo sube el destino: el origen es SIEMPRE el mismo, asi que el reflejo se repite en los tres tercios
	add hl,de			;7048
	ex de,hl			;7049
	pop hl			;704a
	pop bc			;704b
	djnz L_703B		;704c
	ld hl,02750h		;704e   ; la red: cinco tiles de patron
	ld de,07386h		;7051
	call descomprime_tres_tercios		;7054
	ld hl,00750h		;7057   ; y su color
	ld de,073a2h		;705a
	jp descomprime_tres_tercios		;705d

; ----------------------------------------------------------------------
; ===== La copia reflejada =====
; ----------------------------------------------------------------------
copia_reflejando:		; copia BC bytes de VRAM a VRAM dandole la vuelta a cada uno
	call 0004ah		;7060   ; BIOS RDVRM - Reads the content of VRAM | lee un byte de la VRAM en HL
	call invierte_los_bits		;7063   ; le da la vuelta a los ocho bits
	ex de,hl			;7066
	call 0004dh		;7067   ; BIOS WRTVRM - Writes data in VRAM | y lo escribe en DE
	ex de,hl			;706a
	inc hl			;706b   ; asi la mitad de la pista se dibuja una vez y la otra sale de reflejarla
	inc de			;706c
	dec bc			;706d
	ld a,b			;706e
	or c			;706f
	jr nz,copia_reflejando		;7070
	ret			;7072
carga_sprites_de_la_pelota:		; los 16 sprites comprimidos, a 0x1940
	ld de,07d26h		;7073
	jp descomprime		;7076
arranca_la_partida:		; monta pista, sprites, marcador y pantalla de nombres
	ld a,001h		;7079
	ld (0e052h),a		;707b   ; (0xE052) marca que la pantalla se esta montando
	call monta_la_pista		;707e
	call carga_sprites_de_la_pelota		;7081
	call prepara_a_los_jugadores		;7084
	call L_7DED		;7087   ; la pantalla de nombres entera
	call pinta_el_marcador		;708a
	jp vuelca_los_sprites		;708d   ; y el sonido
cuenta_el_montaje:		; baja el contador de montaje hasta que se pasa de 3
	call corre_el_punto		;7090
	ld hl,0e052h		;7093
	ld a,(hl)			;7096
	cp 003h		;7097   ; tres pasos, y a cero
	ret c			;7099
	xor a			;709a
	ld (hl),a			;709b
	ret			;709c
L_709D:
	ld hl,0e130h		;709d   ; la fase del punto
	ld a,(hl)			;70a0   ; leida
	dec a			;70a1   ; la 1 es el saque
	jr nz,L_70BE		;70a2   ; y fuera de ella, se juega
	inc hl			;70a4   ; el paso dentro de la fase
	ld a,(hl)			;70a5   ; leido
	and a			;70a6   ; a cero
	jr z,L_70BB		;70a7   ; aun se esta colocando
	dec a			;70a9   ; el paso 1
	jr nz,L_70BE		;70aa   ; y de ahi arriba, a jugar
	ld a,(0e10eh)		;70ac   ; (0xE10E): la pelota tiene que estar cayendo
	and a			;70af   ; si sube
	ret z			;70b0   ; no se saca
	ld a,(0e104h)		;70b1   ; la altura
	cp 043h		;70b4   ; por encima de 0x43 aun esta alta
	jr nc,L_70E2		;70b6   ; y entonces se decide por otro camino
	ld a,004h		;70b8   ; 4: el mando fingido que golpea
	ret			;70ba   ; y se devuelve
L_70BB:
	ld a,001h		;70bb   ; 1: el que solo coloca
	ret			;70bd   ; y se devuelve
L_70BE:
	ld c,047h		;70be   ; 0x47, el umbral por omision
	ld a,(0e150h)		;70c0   ; el alcance del ultimo golpe
	cp 02ah		;70c3
	jr nz,L_70C9		;70c5
	ld c,040h		;70c7
L_70C9:
	ld a,(0e10ch)		;70c9   ; (0xE10C): de quien es el turno
	and a			;70cc   ; a cero
	jr z,L_70E2		;70cd   ; no se saca
	ld a,(0e100h)		;70cf   ; la coordenada de la pelota
	cp c			;70d2   ; contra el umbral
	jr nc,L_70E2		;70d3   ; y pasado, tampoco
	ld a,(0e150h)		;70d5   ; el alcance del ultimo golpe
	cp 02ah		;70d8   ; 0x2A es el rebote de la red
	ld a,004h		;70da   ; 4: el mando fingido que golpea
	jr nz,L_70E3		;70dc   ; y si no fue la red, ese
	ld a,001h		;70de
	jr L_70E3		;70e0
L_70E2:
	xor a			;70e2
L_70E3:
	ld b,a			;70e3   ; el mando fingido que se lleva
	ld a,(0e10dh)		;70e4   ; hacia donde va la pelota
	and a			;70e7   ; a cero
	ld a,000h		;70e8   ; sin bit de lado
	jr z,L_70EE		;70ea   ; ese
	ld a,010h		;70ec   ; y si no, el bit 4: el otro lado
L_70EE:
	or b			;70ee   ; sumado a lo que ya habia
	ret			;70ef   ; hecho

; ----------------------------------------------------------------------
; DATOS rle_patrones_de_la_pista: 586 bytes -> 744 de PATRONES (93 tiles) en
;   0x2200, 0x2A00 y 0x3200. Lo carga 0x702D con L_4739
;   0x70f0..0x733a  (586 bytes)
DATA_rle_patrones_de_la_pista:
	defb 089h,063h,066h,06ch,078h,07ch,06eh,067h,000h,03eh,005h,063h,09bh,03eh,000h,063h	; 70f0  .cflx|ng.>.c.>.c
	defb 073h,07bh,07fh,06fh,067h,063h,000h,01ch,036h,063h,063h,07fh,063h,063h,000h,063h	; 7100  s{.ogc..6cc.cc.c
	defb 077h,07fh,07fh,06bh,063h,063h,000h,03ch,005h,018h,081h,03ch,010h,000h,081h,0ffh	; 7110  w..kcc.<...<....
	defb 008h,001h,0a4h,0c7h,0cfh,0dfh,0bbh,070h,060h,06ah,02ah,0e7h,0fbh,0fdh,0feh,0feh	; 7120  .......p`j*.....
	defb 03eh,03eh,026h,048h,050h,049h,026h,010h,038h,07fh,07fh,006h,006h,00ch,018h,03ch	; 7130  >>&HPI&.8......<
	defb 0feh,0f2h,0e0h,07fh,07fh,03fh,01fh,004h,000h,08dh,0c7h,0dfh,0bfh,0b4h,060h,04ah	; 7140  .....?........`J
	defb 04ah,040h,0f7h,0fbh,0fdh,0fch,07eh,003h,03eh,094h,07fh,080h,0a6h,098h,040h,03fh	; 7150  J@....~.>.....@?
	defb 060h,0c0h,03eh,0feh,07eh,07fh,0ffh,07fh,03fh,038h,0c0h,0e0h,073h,000h,003h,0c0h	; 7160  `.>.~...?8..s...
	defb 099h,0f0h,077h,0efh,0dfh,03bh,070h,060h,06ah,02ah,0dfh,0dfh,0cfh,0f7h,0f0h,0f0h	; 7170  ..w..;p`j*......
	defb 0fch,0fch,048h,050h,049h,026h,0d0h,0d8h,0cfh,0f7h,003h,003h,003h,00fh,003h,03fh	; 7180  ..HPI&.........?
	defb 007h,0ffh,004h,000h,003h,003h,003h,00fh,003h,03fh,003h,0ffh,002h,0feh,082h,0fch	; 7190  .........?......
	defb 0f8h,003h,003h,081h,00fh,005h,000h,084h,030h,033h,033h,03fh,003h,033h,087h,039h	; 71a0  ........033?.3.9
	defb 01fh,019h,019h,018h,01fh,00fh,006h,000h,002h,0ffh,081h,000h,004h,001h,006h,000h	; 71b0  ................
	defb 002h,0ffh,088h,088h,0ffh,088h,0ffh,088h,0ffh,088h,0ffh,006h,001h,002h,0ffh,003h	; 71c0  ................
	defb 000h,005h,080h,006h,000h,002h,0ffh,004h,00fh,004h,01fh,088h,000h,056h,074h,054h	; 71d0  .............VtT
	defb 056h,054h,054h,056h,004h,00fh,004h,01fh,00ah,0ffh,006h,001h,004h,03fh,004h,07fh	; 71e0  VTTV.........?..
	defb 008h,001h,004h,000h,004h,001h,004h,003h,004h,007h,004h,00fh,004h,01fh,004h,000h	; 71f0  ................
	defb 004h,001h,005h,0ffh,003h,000h,005h,0feh,003h,000h,003h,001h,005h,000h,003h,0ffh	; 7200  ................
	defb 005h,000h,003h,0ffh,081h,0f0h,004h,0e0h,003h,0ffh,005h,000h,081h,01fh,005h,03fh	; 7210  ...............?
	defb 005h,07fh,005h,0ffh,005h,001h,003h,003h,008h,008h,002h,000h,002h,001h,002h,003h	; 7220  ................
	defb 002h,007h,002h,00fh,002h,01fh,002h,03fh,002h,07fh,0c4h,0e3h,0f3h,0fbh,0ddh,00eh	; 7230  .......?........
	defb 056h,056h,054h,012h,00ah,012h,034h,028h,01ch,0feh,0feh,07fh,080h,090h,090h,040h	; 7240  VVT...4(.......@
	defb 07fh,0e0h,0c0h,012h,00ah,012h,034h,02bh,01bh,0f3h,0efh,0f7h,0efh,0dfh,0bbh,070h	; 7250  ......4+.......p
	defb 060h,06ah,02ah,0b6h,0b6h,032h,030h,078h,07ch,080h,000h,0b6h,0b6h,032h,030h,07bh	; 7260  `j*..20x|....20{
	defb 07fh,083h,00fh,0b7h,0b7h,033h,03fh,07fh,07fh,0bfh,03fh,0d2h,0f3h,061h,000h,003h	; 7270  .....3?...?..a..
	defb 0c0h,09dh,0f0h,0ceh,086h,084h,080h,010h,03ch,0c0h,000h,0ceh,086h,084h,080h,013h	; 7280  ........<.......
	defb 03fh,0c3h,00fh,0cfh,087h,087h,08fh,01fh,03fh,0ffh,03fh,0cch,0ffh,073h,000h,003h	; 7290  ?.......?.?..s..
	defb 0c0h,08ah,0f0h,000h,018h,03ch,07eh,0ffh,0ffh,03ch,03ch,001h,007h,000h,08ch,0c0h	; 72a0  .....<~..<<.....
	defb 0c3h,0cfh,09bh,017h,037h,03fh,03fh,007h,0c3h,0f1h,0f8h,004h,0fch,002h,03fh,008h	; 72b0  ....7??.......?.
	defb 07fh,002h,03fh,091h,0dfh,0cfh,0c0h,0f0h,0f7h,0efh,0dfh,0bbh,070h,060h,06ah,02ah	; 72c0  ..?.........p`j*
	defb 0ffh,0ffh,0feh,0fch,0fch,003h,0fah,002h,0feh,002h,0fch,004h,0fah,094h,0c7h,0c3h	; 72d0  ................
	defb 0c3h,0f1h,0f1h,0f0h,0fch,0fch,03bh,0f7h,07eh,07eh,0fdh,07dh,03fh,038h,080h,080h	; 72e0  ......;.~~.}?8..
	defb 000h,000h,003h,0c0h,099h,0f0h,037h,02fh,01fh,03bh,070h,060h,06ah,02ah,0c2h,0c8h	; 72f0  ......7/.;p`j*..
	defb 0c0h,0a3h,00fh,04dh,01bh,01bh,047h,00bh,001h,0e2h,0f8h,0fdh,0fch,0fch,004h,03fh	; 7300  ...M..G........?
	defb 006h,07fh,0a6h,03fh,01fh,000h,000h,004h,006h,07fh,080h,090h,090h,0c0h,0ffh,0c0h	; 7310  ...?............
	defb 080h,0f7h,0fbh,0fdh,0fch,07eh,03eh,03eh,03dh,07fh,080h,090h,090h,040h,03fh,060h	; 7320  .....~>>=....@?`
	defb 0c0h,000h,022h,055h,045h,075h,057h,055h,025h,000h	; 7330  .."UEuWU%.

; ----------------------------------------------------------------------
; DATOS rle_color_de_la_pista: 76 bytes -> 744 de COLOR, cargado DOS veces: en
;   0x0200 por 0x701B y en 0x0500 por 0x7024, las dos con L_4739
;   0x733a..0x7386  (76 bytes)
DATA_rle_color_de_la_pista:
	defb 030h,0f4h,082h,011h,0ffh,006h,066h,010h,0f6h,07fh,047h,011h,047h,01bh,0f6h,005h	; 733a  0.....f...G.G...
	defb 0c6h,008h,0fch,008h,01ch,008h,0fch,010h,0f6h,006h,0c6h,002h,0ffh,008h,0f0h,002h	; 734a  ................
	defb 0f6h,006h,0c6h,002h,0f6h,006h,0c6h,008h,0fch,008h,0c6h,008h,0fch,01dh,0c6h,003h	; 735a  ................
	defb 0f6h,010h,0cfh,013h,0e6h,005h,061h,008h,0e1h,018h,016h,008h,0f4h,010h,064h,068h	; 736a  ......a.......dh
	defb 047h,008h,060h,008h,0f6h,07fh,047h,011h,047h,008h,0f0h,000h	; 737a  G.`...G.G...

; ----------------------------------------------------------------------
; DATOS rle_patrones_de_la_red: 28 bytes -> 40 de PATRONES (5 tiles) en
;   0x2750, 0x2F50 y 0x3750. Lo carga 0x7051
;   0x7386..0x73a2  (28 bytes)
DATA_rle_patrones_de_la_red:
	defb 008h,020h,082h,000h,038h,005h,010h,083h,038h,000h,07ch,005h,028h,083h,07ch,000h	; 7386  . ..8...8.|.(.|.
	defb 0feh,005h,054h,085h,0feh,000h,00ah,004h,00ah,004h,000h,000h	; 7396  ..T.........

; ----------------------------------------------------------------------
; DATOS rle_color_de_la_red: 5 bytes -> 40 de COLOR en 0x0750, 0x0F50 y
;   0x1750. Lo carga 0x705A
;   0x73a2..0x73a7  (5 bytes)
DATA_rle_color_de_la_red:
	defb 008h,0f0h,020h,070h,000h	; 73a2

; ----------------------------------------------------------------------
; DATOS patrones_de_los_jugadores: 40 bloques comprimidos pegados, uno por
;   fotograma, todos a la tabla de sprites: los 20 del cercano a 0x1800 y los
;   20 del lejano a 0x18A0. Los descomprime L_5E9B a traves del puntero del
;   fotograma
;   0x73a7..0x7d26  (2431 bytes)
DATA_patrones_de_los_jugadores:
	defb 000h,018h,084h,007h,00fh,01fh,07fh,005h,0ffh,082h,07fh,03eh,005h,000h,08bh,080h	; 73a7  ...........>....
	defb 0f8h,0fch,080h,0f8h,0fch,08eh,0f3h,01dh,0e6h,078h,005h,000h,089h,070h,0f8h,0bch	; 73b7  .........x...p..
	defb 0deh,06eh,036h,01bh,00ch,007h,007h,003h,006h,000h,083h,0feh,001h,0feh,007h,0ffh	; 73c7  .n6.............
	defb 007h,000h,089h,080h,0c0h,060h,0b0h,0d8h,0ech,0f4h,0fah,0fah,020h,000h,083h,003h	; 73d7  .....`...... ...
	defb 001h,001h,00dh,000h,004h,0ffh,086h,07fh,03fh,01fh,00fh,007h,001h,006h,000h,002h	; 73e7  ........?.......
	defb 0fdh,003h,0ffh,002h,0feh,083h,0fch,0f8h,0e0h,006h,000h,000h,000h,018h,087h,000h	; 73f7  ................
	defb 001h,007h,007h,00fh,01fh,03fh,004h,07fh,082h,03fh,01ch,003h,000h,08ch,070h,0f8h	; 7407  .....?...?....p.
	defb 0e0h,0c0h,0fch,0feh,0c3h,0fch,0c6h,0fch,0f0h,080h,011h,000h,083h,038h,0eeh,093h	; 7417  .............8..
	defb 00fh,000h,086h,080h,000h,001h,002h,003h,003h,00bh,000h,088h,080h,0e0h,0f8h,038h	; 7427  ...............8
	defb 0cfh,0f2h,03dh,00fh,006h,007h,002h,003h,081h,07ch,00bh,0ffh,08ah,07fh,01fh,007h	; 7437  ..=......|......
	defb 001h,0e0h,038h,0cch,0f6h,0fah,0fbh,003h,0fdh,087h,0ffh,0feh,0feh,0fch,0fch,0f8h	; 7447  ..8.............
	defb 0e0h,000h,000h,018h,083h,001h,006h,01fh,003h,03fh,002h,07fh,003h,0ffh,083h,09eh	; 7457  .........?......
	defb 06ch,030h,003h,000h,089h,0f0h,0fch,00eh,0f0h,0fch,08eh,0f8h,0fch,080h,009h,000h	; 7467  l0..............
	defb 003h,00fh,00ah,000h,083h,001h,003h,007h,003h,0ffh,083h,007h,003h,001h,007h,000h	; 7477  ................
	defb 082h,03fh,07fh,00bh,0ffh,086h,07fh,03fh,000h,0f0h,0fch,0feh,009h,0ffh,084h,0feh	; 7487  .?.....?........
	defb 0fch,0f0h,000h,000h,000h,018h,086h,000h,003h,017h,03eh,03dh,03fh,003h,07fh,003h	; 7497  ..........>=?...
	defb 0ffh,08dh,08fh,0f6h,078h,000h,0e0h,0c0h,038h,0f0h,0c8h,0b8h,0f0h,0e0h,0c0h,003h	; 74a7  ....x...8.......
	defb 080h,005h,000h,082h,003h,00fh,00dh,000h,085h,0c0h,0f0h,0f8h,0f8h,0fch,003h,0feh	; 74b7  ................
	defb 003h,0ffh,002h,0feh,083h,0fch,0f8h,0e0h,003h,000h,006h,002h,089h,001h,007h,01fh	; 74c7  ................
	defb 05fh,0ech,0f0h,040h,03fh,07fh,00ah,0ffh,084h,03fh,0cfh,076h,018h,000h,000h,018h	; 74d7  _..@?....?.v....
	defb 086h,00dh,01bh,01bh,036h,036h,0beh,004h,0ffh,003h,07fh,087h,031h,02fh,01eh,000h	; 74e7  ....66......1/..
	defb 000h,040h,040h,004h,0c0h,005h,080h,003h,000h,08ah,001h,007h,00fh,00fh,01fh,01fh	; 74f7  .@@.............
	defb 03fh,03fh,07fh,07fh,003h,0bfh,002h,05fh,085h,01fh,0e0h,0f8h,0fch,0feh,004h,0ffh	; 7507  ??....._........
	defb 002h,0feh,002h,0fch,002h,0f8h,089h,0f0h,090h,01ch,019h,038h,030h,050h,0e0h,060h	; 7517  ...........80P.`
	defb 009h,000h,082h,030h,0c0h,00eh,000h,000h,000h,018h,084h,000h,003h,007h,00fh,004h	; 7527  ...0............
	defb 000h,094h,019h,00fh,007h,01fh,00eh,018h,000h,000h,0fch,0feh,0e7h,0dfh,0dfh,0bfh	; 7537  ................
	defb 07fh,07eh,0fch,0f8h,0f0h,080h,00ah,000h,083h,07fh,080h,07fh,007h,0ffh,089h,00eh	; 7547  .~..............
	defb 01fh,03dh,07bh,076h,06ch,0d8h,030h,0e0h,007h,0c0h,017h,000h,08ch,001h,003h,006h	; 7557  .={vl.0.........
	defb 00dh,01bh,037h,02fh,05fh,05fh,0c0h,080h,080h,01dh,000h,002h,0bfh,003h,0ffh,002h	; 7567  ..7/__..........
	defb 07fh,083h,03fh,01fh,007h,006h,000h,004h,0ffh,086h,0feh,0fch,0f8h,0f0h,0e0h,080h	; 7577  ..?.............
	defb 006h,000h,000h,000h,018h,083h,003h,00fh,007h,003h,001h,087h,000h,038h,01fh,00fh	; 7587  .............8..
	defb 03fh,01fh,03eh,003h,000h,08ch,0c0h,0f8h,0feh,0ffh,0e3h,0dfh,0bfh,07fh,0feh,0fch	; 7597  ?.>.............
	defb 0f0h,080h,013h,000h,081h,001h,00dh,000h,08bh,01ch,077h,0c9h,001h,007h,01fh,01ch	; 75a7  ..........w.....
	defb 0f3h,04fh,0bch,0f0h,006h,0e0h,002h,0c0h,085h,000h,080h,040h,0c0h,0c0h,00bh,000h	; 75b7  .O.........@....
	defb 086h,007h,01ch,033h,06fh,05fh,0dfh,003h,0bfh,088h,0ffh,07fh,07fh,03fh,03fh,01fh	; 75c7  ...3o_.......??.
	defb 007h,03eh,00bh,0ffh,084h,0feh,0f8h,0e0h,080h,000h,000h,018h,08ch,007h,003h,051h	; 75d7  .>.............Q
	defb 058h,028h,0ach,057h,03fh,01fh,00fh,007h,003h,004h,000h,08ch,0c0h,0b0h,07ch,07eh	; 75e7  X(.W?.........|~
	defb 0ffh,087h,07bh,0ffh,0ffh,0fch,0e0h,080h,004h,000h,083h,080h,0c0h,0e0h,003h,0ffh	; 75f7  ..{.............
	defb 083h,0e0h,000h,080h,00ah,000h,003h,0f0h,00ah,000h,083h,00fh,03fh,07fh,009h,0ffh	; 7607  ............?...
	defb 086h,07fh,03fh,00fh,000h,0fch,0feh,00bh,0ffh,083h,0feh,0fch,000h,000h,000h,018h	; 7617  ..?.............
	defb 08ch,020h,028h,0a8h,0dch,054h,074h,03ch,01eh,01fh,00fh,00fh,007h,006h,000h,093h	; 7627  . (..Tt<........
	defb 080h,0c0h,0f0h,07ch,01eh,0e6h,0ffh,0ffh,0f1h,0eeh,0eeh,018h,000h,000h,003h,00fh	; 7637  ...|............
	defb 01fh,01fh,03fh,003h,07fh,003h,0ffh,002h,07fh,086h,03fh,01fh,007h,000h,0c0h,0f0h	; 7647  ..?.......?.....
	defb 00dh,000h,082h,0fch,0feh,00ah,0ffh,084h,0fch,0f3h,06eh,018h,003h,000h,006h,040h	; 7657  ..........n....@
	defb 087h,080h,0e0h,0f8h,0fah,037h,00fh,002h,000h,000h,018h,090h,080h,090h,0d4h,0dch	; 7667  .....7..........
	defb 0b8h,0f1h,0e1h,0e1h,0f1h,0fch,0ffh,07fh,03fh,01ch,00bh,007h,006h,000h,002h,080h	; 7677  ........?.......
	defb 08ch,0c0h,0e0h,060h,060h,0e0h,020h,0c0h,080h,007h,01fh,03fh,07fh,004h,0ffh,002h	; 7687  ...``. ....?....
	defb 07fh,002h,03fh,002h,01fh,08ch,00fh,009h,080h,0e0h,0f0h,0f0h,0f8h,0f8h,0fch,0fch	; 7697  ..?.............
	defb 0feh,0feh,003h,0fdh,002h,0fah,083h,0f8h,00ch,003h,00eh,000h,087h,038h,098h,01ch	; 76a7  .............8..
	defb 00ch,00ah,007h,006h,009h,000h,000h,000h,018h,084h,001h,007h,006h,00eh,006h,00fh	; 76b7  ................
	defb 003h,007h,08eh,003h,001h,000h,0c0h,0e0h,036h,006h,0c0h,0e0h,09ch,0f3h,0ceh,0fch	; 76c7  ........6.......
	defb 0f8h,003h,0f0h,089h,0e0h,000h,060h,0fch,0ffh,09fh,064h,01bh,005h,00ch,000h,088h	; 76d7  ......`...d.....
	defb 0c0h,070h,090h,0e0h,078h,01eh,007h,001h,005h,000h,085h,080h,0e0h,078h,01eh,006h	; 76e7  .p..x........x..
	defb 01bh,000h,000h,000h,018h,086h,002h,001h,007h,01fh,03eh,07eh,004h,0ffh,083h,07fh	; 76f7  ..........>~....
	defb 03fh,00fh,004h,000h,08bh,080h,0c0h,080h,000h,03ch,0f2h,08ch,0f4h,0c8h,0f0h,0c0h	; 7707  ?........<......
	defb 004h,000h,081h,07fh,003h,0ffh,00dh,000h,084h,09eh,0feh,0e0h,03fh,00bh,000h,002h	; 7717  ............?...
	defb 0ffh,082h,000h,0ffh,00ch,000h,084h,0f0h,0f8h,008h,0f0h,00ch,000h,000h,000h,018h	; 7727  ................
	defb 087h,006h,00eh,01ch,01ch,03fh,03fh,07fh,003h,0ffh,084h,03fh,0dfh,06eh,028h,003h	; 7737  .....??....?.n(.
	defb 000h,08bh,018h,030h,0f8h,0f0h,0f8h,0f0h,0f0h,0e0h,0e0h,0c0h,080h,007h,000h,086h	; 7747  ...0............
	defb 003h,007h,007h,004h,003h,006h,007h,000h,088h,003h,033h,0f8h,0f7h,0cch,038h,0e0h	; 7757  ..........3...8.
	defb 080h,00bh,000h,088h,003h,00fh,03ch,0f3h,0ceh,038h,0e0h,080h,005h,000h,087h,00eh	; 7767  ......<..8......
	defb 03dh,0f3h,0ceh,038h,0e0h,080h,009h,000h,000h,000h,018h,084h,000h,001h,003h,004h	; 7777  =..8............
	defb 004h,000h,08fh,001h,003h,007h,00fh,00ch,007h,003h,000h,020h,0b0h,031h,033h,032h	; 7787  ........... .132
	defb 076h,0feh,003h,0fch,085h,0f8h,0f0h,0e0h,040h,080h,014h,000h,002h,001h,003h,003h	; 7797  v.......@.......
	defb 099h,00fh,019h,037h,06eh,0dch,038h,0d0h,060h,000h,001h,003h,007h,00fh,01fh,03fh	; 77a7  ...7n.8.`......?
	defb 07fh,0ffh,002h,0fdh,0fah,0e4h,098h,0e0h,000h,078h,003h,0fch,086h,0f4h,0e8h,0d0h	; 77b7  .........x......
	defb 0a0h,040h,080h,006h,000h,000h,000h,018h,086h,002h,013h,031h,031h,071h,071h,004h	; 77c7  .@.........11qq.
	defb 0f3h,084h,0feh,09ch,0e8h,070h,004h,000h,007h,080h,007h,000h,083h,00fh,03fh,07fh	; 77d7  .....p........?.
	defb 004h,0ffh,08ch,0f8h,0fbh,043h,0bbh,05bh,023h,01bh,000h,003h,0c0h,0f0h,0f8h,004h	; 77e7  .....C.[#.......
	defb 0fch,002h,07ch,087h,008h,074h,068h,010h,060h,000h,000h,003h,0c0h,01dh,000h,000h	; 77f7  ..|..th.`.......
	defb 000h,018h,08ch,000h,00ch,03ch,038h,001h,001h,01fh,053h,0adh,036h,00bh,001h,004h	; 7807  .....<8...S.6...
	defb 000h,08ch,070h,0f8h,03ch,05eh,0dfh,0efh,0f3h,0ffh,0ffh,07eh,0fch,0f0h,007h,000h	; 7817  ..p.<^.....~....
	defb 088h,003h,00eh,009h,007h,01eh,078h,0e0h,080h,005h,000h,087h,006h,03fh,0ffh,0f9h	; 7827  ......x......?..
	defb 026h,0d8h,0a0h,019h,000h,085h,001h,007h,01eh,078h,060h,00bh,000h,000h,000h,018h	; 7837  &........x`.....
	defb 08bh,001h,003h,006h,001h,003h,000h,0dbh,02dh,006h,003h,001h,005h,000h,08dh,0c0h	; 7847  ........-.......
	defb 080h,0e0h,0f8h,03ch,0beh,0bfh,0bfh,0dfh,0e7h,0ffh,0feh,03ch,004h,000h,084h,079h	; 7857  ...<.......<...y
	defb 07fh,007h,0fch,00bh,000h,081h,0feh,003h,0ffh,00ch,000h,084h,00fh,01fh,010h,00fh	; 7867  ................
	defb 00ch,000h,002h,0ffh,082h,000h,0ffh,00ch,000h,000h,000h,018h,004h,000h,08ah,001h	; 7877  ................
	defb 081h,0d0h,058h,02bh,00dh,006h,007h,003h,001h,005h,000h,095h,0c0h,0f0h,088h,0f0h	; 7887  ..X+............
	defb 0fch,03eh,00fh,0dfh,0dfh,0efh,0f7h,0feh,03ch,0c0h,0cch,01fh,0efh,033h,01ch,007h	; 7897  .>......<....3..
	defb 001h,00bh,000h,086h,0c0h,0e0h,0e0h,020h,0c0h,060h,007h,000h,087h,070h,0bch,0cfh	; 78a7  ....... .`...p..
	defb 073h,01ch,007h,001h,00ch,000h,088h,0c0h,0f0h,03ch,0cfh,073h,01ch,007h,001h,005h	; 78b7  s........<.s....
	defb 000h,000h,000h,018h,095h,003h,080h,086h,0a3h,0d5h,052h,06eh,07dh,07bh,03bh,03bh	; 78c7  ..........Rn}{;;
	defb 01fh,01ch,00bh,007h,000h,080h,0c0h,060h,080h,0c0h,005h,0e0h,085h,0f0h,0e0h,020h	; 78d7  .......`....... 
	defb 0c0h,080h,004h,000h,002h,080h,003h,0c0h,088h,0f0h,098h,0ech,076h,03bh,01ch,00bh	; 78e7  ............v;..
	defb 006h,010h,000h,081h,01eh,003h,03fh,086h,02fh,017h,00bh,005h,002h,001h,007h,000h	; 78f7  ......?./.......
	defb 08fh,080h,0c0h,0e0h,0f0h,0f8h,0fch,0feh,0ffh,040h,0bfh,05fh,027h,019h,007h,000h	; 7907  .........@._'...
	defb 000h,000h,018h,086h,002h,013h,031h,031h,071h,071h,004h,0f3h,084h,0feh,09ch,0e8h	; 7917  ......11qq......
	defb 070h,004h,000h,007h,080h,007h,000h,083h,00fh,03fh,07fh,004h,0ffh,08ch,0f8h,0fbh	; 7927  p........?......
	defb 043h,0bbh,05bh,023h,01bh,000h,003h,0c0h,0f0h,0f8h,004h,0fch,002h,07ch,087h,008h	; 7937  C.[#.........|..
	defb 074h,068h,010h,060h,000h,000h,003h,0c0h,01dh,000h,000h,0a0h,018h,088h,01fh,03dh	; 7947  th.`...........=
	defb 078h,0e1h,0c1h,0c3h,04fh,01eh,009h,000h,081h,0e0h,003h,0f0h,082h,0e0h,080h,009h	; 7957  x...O...........
	defb 000h,08dh,00eh,011h,02eh,076h,0f9h,0fdh,0feh,0ffh,07fh,07fh,03fh,01fh,007h,003h	; 7967  .....v......?...
	defb 000h,08dh,010h,0b8h,050h,0e0h,0d0h,090h,068h,068h,0a8h,0d0h,0e0h,0c0h,080h,003h	; 7977  ....P...hh......
	defb 000h,000h,0a0h,018h,089h,003h,03fh,05ch,0bch,070h,060h,041h,047h,00ch,007h,000h	; 7987  ......?\.p`AG...
	defb 087h,0e0h,0f0h,030h,030h,070h,0e0h,0c0h,00bh,000h,084h,00fh,070h,08eh,07fh,003h	; 7997  ...00p......p...
	defb 0ffh,081h,038h,006h,000h,088h,00fh,0efh,01fh,0f8h,0f8h,078h,0b8h,0d0h,008h,000h	; 79a7  ..8........x....
	defb 000h,0a0h,018h,089h,01fh,03fh,07fh,0efh,00fh,00ch,018h,018h,016h,008h,000h,081h	; 79b7  .....?..........
	defb 0e0h,003h,0f8h,081h,010h,00ah,000h,084h,07fh,0c0h,0bfh,07fh,00ch,000h,084h,0f0h	; 79c7  ................
	defb 00fh,0dfh,0d3h,00ch,000h,003h,0e0h,01dh,000h,000h,0a0h,018h,08ah,00fh,03fh,07fh	; 79d7  ..............?.
	defb 07fh,0dbh,0b6h,06ch,000h,001h,001h,006h,000h,081h,080h,007h,0c0h,081h,080h,009h	; 79e7  ...l............
	defb 000h,086h,00fh,07fh,0ffh,030h,0cfh,030h,008h,000h,086h,00fh,0efh,0ffh,0f0h,010h	; 79f7  .....0.0........
	defb 0e0h,00ah,000h,000h,0a0h,018h,082h,078h,0feh,003h,0ffh,084h,0fdh,06dh,034h,014h	; 7a07  .......x.....m4.
	defb 009h,000h,087h,080h,0c0h,0e0h,0b0h,090h,080h,080h,007h,000h,002h,007h,087h,03fh	; 7a17  ...............?
	defb 07fh,0ffh,07fh,09fh,060h,01fh,009h,000h,087h,0e0h,0f0h,0f8h,0f0h,0c8h,030h,0c0h	; 7a27  ....`.........0.
	defb 007h,000h,000h,0a0h,018h,089h,07ch,0ffh,0fbh,0f1h,0f0h,078h,038h,02eh,017h,009h	; 7a37  ......|....x8...
	defb 000h,087h,080h,0c0h,0c0h,060h,000h,000h,080h,007h,000h,08dh,043h,0ech,053h,03bh	; 7a47  .....`......C.S;
	defb 05ch,04dh,0b3h,0b7h,0afh,05fh,03fh,01fh,00fh,003h,000h,084h,080h,040h,0a0h,070h	; 7a57  \M..._?......@.p
	defb 004h,0f8h,002h,0f0h,082h,0e0h,0c0h,004h,000h,000h,0a0h,018h,08ah,078h,0feh,0ffh	; 7a67  .............x..
	defb 087h,083h,001h,040h,020h,03ch,01eh,00ah,000h,083h,090h,0b0h,0c0h,009h,000h,089h	; 7a77  ...@ <..........
	defb 0f0h,0f7h,0f8h,01fh,01fh,01eh,01dh,00bh,001h,009h,000h,084h,0f0h,00eh,071h,0feh	; 7a87  ..............q.
	defb 003h,0ffh,081h,01ch,006h,000h,000h,0a0h,018h,08ah,03ch,07eh,0efh,0f7h,0fbh,07ah	; 7a97  ..........<~...z
	defb 038h,01ch,00eh,003h,008h,000h,084h,020h,0e8h,018h,0f0h,00ah,000h,084h,00fh,0f0h	; 7aa7  8...... ........
	defb 0fbh,0cbh,00ch,000h,084h,0feh,003h,0fdh,0feh,00ch,000h,003h,0e0h,01dh,000h,000h	; 7ab7  ................
	defb 0a0h,018h,08ch,03ch,07eh,077h,0fbh,0fbh,0f7h,0c2h,0e1h,060h,020h,00ch,004h,007h	; 7ac7  ...<~w.....` ...
	defb 000h,002h,080h,002h,0c0h,082h,040h,080h,007h,000h,086h,0f0h,0f7h,0ffh,00fh,008h	; 7ad7  ......@.........
	defb 007h,00ch,000h,086h,0f0h,0feh,0ffh,00ch,0f3h,00ch,008h,000h,000h,0a0h,018h,08ah	; 7ae7  ................
	defb 007h,01dh,03bh,07bh,077h,0b7h,0cdh,00ah,015h,00bh,006h,000h,081h,080h,007h,0c0h	; 7af7  ..;{w...........
	defb 081h,080h,007h,000h,002h,007h,087h,03fh,07fh,0ffh,07fh,09fh,060h,01fh,009h,000h	; 7b07  .......?....`...
	defb 087h,0e0h,0f0h,0f8h,0f0h,0c8h,030h,0c0h,007h,000h,000h,0a0h,018h,08ch,01ch,006h	; 7b17  ......0.........
	defb 083h,0c3h,0e3h,071h,07bh,03fh,03fh,01fh,00fh,007h,007h,000h,007h,080h,006h,000h	; 7b27  ...q{??.........
	defb 08dh,007h,01fh,03fh,07fh,07fh,0ffh,0feh,0fdh,0f9h,076h,02eh,011h,00eh,003h,000h	; 7b37  ...?......v.....
	defb 08dh,080h,0c0h,0e0h,0d0h,0a8h,068h,068h,090h,0d0h,0e0h,050h,0b8h,010h,003h,000h	; 7b47  ......hh...P....
	defb 000h,0a0h,018h,08dh,00ch,006h,003h,011h,018h,00ch,00eh,016h,0f7h,077h,07bh,03fh	; 7b57  .............w{?
	defb 01eh,00ah,000h,004h,080h,005h,000h,083h,00fh,03fh,07fh,005h,0ffh,085h,09eh,066h	; 7b67  .........?.....f
	defb 019h,006h,001h,004h,000h,08ch,0c0h,0f0h,0d8h,0bch,0bch,060h,05ch,0dfh,0e3h,0dch	; 7b77  ...........`\...
	defb 023h,0c0h,003h,000h,002h,0c0h,081h,080h,01dh,000h,000h,0a0h,018h,08ch,038h,068h	; 7b87  #.............8h
	defb 01ch,03fh,067h,007h,01bh,0fbh,07dh,01eh,00fh,003h,008h,000h,082h,080h,0c0h,003h	; 7b97  .?g...}.........
	defb 0e0h,083h,060h,0c0h,080h,004h,000h,087h,03fh,07fh,0ffh,07fh,0bfh,040h,03fh,009h	; 7ba7  ..`.....?....@?.
	defb 000h,087h,0d0h,0dbh,0dfh,0dch,0d3h,00ch,0f0h,009h,000h,002h,0e0h,082h,000h,0e0h	; 7bb7  ................
	defb 01ch,000h,000h,0a0h,018h,087h,0c0h,0e0h,0c0h,060h,026h,00eh,00ch,01ah,000h,085h	; 7bc7  .........`&.....
	defb 00eh,017h,03bh,07dh,0beh,003h,0bfh,002h,05fh,095h,027h,018h,007h,000h,000h,008h	; 7bd7  ..;}...._.'.....
	defb 01ch,0a8h,070h,0a0h,0d0h,070h,0b8h,0d8h,0e8h,0f0h,0e0h,040h,080h,000h,000h,000h	; 7be7  ..p..p.....@....
	defb 0a0h,018h,084h,040h,0c3h,0f3h,07bh,01ch,000h,08dh,006h,000h,016h,079h,0ffh,000h	; 7bf7  ...@..{......y..
	defb 0ffh,0ffh,07fh,0bfh,09fh,060h,01fh,005h,000h,08bh,080h,0e0h,0f0h,000h,0f0h,0f0h	; 7c07  .....`..........
	defb 0e0h,0d0h,090h,060h,080h,003h,000h,000h,0a0h,018h,089h,001h,007h,03fh,07eh,0fch	; 7c17  ...`.........?~.
	defb 0f8h,0fdh,0ffh,01fh,007h,000h,089h,0c0h,080h,010h,010h,030h,070h,0e0h,0c0h,080h	; 7c27  ...........0p...
	defb 007h,000h,08dh,00fh,01fh,03fh,05fh,0afh,0b7h,0b3h,04dh,05ch,03bh,053h,0ech,043h	; 7c37  .....?_...M\;S.C
	defb 004h,000h,084h,0c0h,0e0h,0f0h,0f0h,004h,0f8h,084h,070h,0a0h,040h,080h,003h,000h	; 7c47  ..........p.@...
	defb 000h,0a0h,018h,086h,007h,00eh,018h,000h,001h,047h,003h,0ffh,082h,07fh,03ch,005h	; 7c57  .........G....<.
	defb 000h,08ah,0a0h,020h,060h,0e0h,0c0h,0c0h,0c8h,0f0h,0e0h,0c0h,007h,000h,08ch,003h	; 7c67  ... `...........
	defb 00fh,01bh,03dh,03dh,006h,03ah,0fbh,0c7h,03bh,0c4h,003h,003h,000h,084h,0f0h,0fch	; 7c77  ..==.:..;.......
	defb 0feh,0feh,004h,0ffh,085h,079h,066h,098h,060h,080h,003h,000h,002h,0c0h,081h,080h	; 7c87  .....yf.`.......
	defb 01dh,000h,000h,0a0h,018h,085h,007h,001h,000h,040h,0c1h,003h,0ffh,082h,07fh,00fh	; 7c97  .........@......
	defb 007h,000h,089h,080h,020h,060h,0c0h,080h,000h,0e8h,0d0h,0a0h,006h,000h,087h,00bh	; 7ca7  .... `..........
	defb 0dbh,0fbh,03bh,0cbh,030h,00fh,009h,000h,087h,0fch,0feh,0ffh,0feh,0fdh,002h,0fch	; 7cb7  ..;.0...........
	defb 009h,000h,002h,0e0h,082h,000h,0e0h,01ch,000h,000h,0a0h,018h,087h,00ch,00eh,006h	; 7cc7  ................
	defb 000h,058h,0f0h,0e0h,019h,000h,08eh,040h,0e1h,057h,03bh,016h,02dh,03bh,077h,06fh	; 7cd7  .X.....@.W;.-;wo
	defb 05fh,03fh,01fh,008h,007h,003h,000h,084h,0c0h,0a0h,070h,0f8h,004h,0f4h,002h,0e8h	; 7ce7  _?........p.....
	defb 085h,090h,060h,080h,000h,000h,000h,0a0h,018h,084h,040h,0c3h,0f3h,07bh,01ch,000h	; 7cf7  ..`.......@..{..
	defb 08dh,006h,000h,016h,079h,0ffh,000h,0ffh,0ffh,07fh,0bfh,09fh,060h,01fh,005h,000h	; 7d07  ....y.......`...
	defb 08bh,080h,0e0h,0f0h,000h,0f0h,0f0h,0e0h,0d0h,090h,060h,080h,003h,000h,000h	; 7d17  ..........`....

; ----------------------------------------------------------------------
; DATOS rle_sprites_de_la_pelota: 199 bytes -> 512 de PATRONES DE SPRITE en
;   0x1940 (16 sprites de 16x16). Lo carga 0x7073
;   0x7d26..0x7ded  (199 bytes)
DATA_rle_sprites_de_la_pelota:
	defb 040h,019h,00eh,000h,002h,030h,01dh,000h,083h,020h,070h,020h,01dh,000h,003h,070h	; 7d26  @....0... p ...p
	defb 01ch,000h,084h,030h,078h,078h,030h,01bh,000h,081h,070h,003h,0f8h,081h,070h,010h	; 7d36  ...0xx0...p...p.
	defb 000h,081h,030h,01fh,000h,081h,070h,01fh,000h,083h,020h,070h,020h,01dh,000h,083h	; 7d46  ..0...p... p ...
	defb 030h,078h,030h,01dh,000h,083h,070h,0f8h,070h,01dh,000h,088h,008h,0ffh,008h,07fh	; 7d56  0x0...p.p.......
	defb 008h,07fh,008h,07fh,008h,000h,088h,088h,0ffh,088h,0ffh,088h,0ffh,088h,0ffh,008h	; 7d66  ................
	defb 000h,088h,088h,0ffh,088h,0ffh,088h,0ffh,088h,0ffh,008h,000h,088h,088h,0ffh,088h	; 7d76  ................
	defb 0feh,088h,0feh,088h,0feh,008h,000h,094h,007h,010h,02fh,057h,069h,0b4h,0d8h,065h	; 7d86  ........../Wi..e
	defb 01dh,03dh,01eh,01fh,00fh,003h,000h,000h,080h,0c0h,060h,090h,006h,0f0h,002h,0e0h	; 7d96  .=........`.....
	defb 081h,0c0h,003h,000h,090h,088h,0cch,0ech,06eh,077h,03fh,019h,066h,0dfh,063h,0b5h	; 7da6  ........nw?.f.c.
	defb 0d5h,06eh,01fh,00fh,003h,005h,000h,084h,080h,0c0h,060h,0e0h,004h,0f0h,08dh,030h	; 7db6  .n........`....0
	defb 0e0h,0c0h,01eh,023h,05ch,0e7h,0b3h,0c7h,057h,03bh,03fh,01fh,008h,000h,006h,080h	; 7dc6  ...#\...W;?.....
	defb 008h,000h,08dh,008h,0cch,06ch,076h,03eh,059h,067h,0dfh,0e1h,06fh,05fh,03fh,00eh	; 7dd6  .....lv>Yg..o_?.
	defb 009h,000h,005h,080h,005h,000h,000h	; 7de6

; ======================================================================
; CODIGO 0x7ded..0x7df3  (6 bytes)
; ======================================================================


L_7DED:
	ld de,07df3h		;7ded
	jp descomprime		;7df0

; ----------------------------------------------------------------------
; DATOS rle_pantalla_de_titulo: 440 bytes -> 768 de NOMBRES en 0x3800, o sea
;   la pantalla ENTERA de 32x24. Lo carga 0x7DED
;   0x7df3..0x7fab  (440 bytes)
DATA_rle_pantalla_de_titulo:
	defb 000h,038h,087h,0aah,0a9h,0aah,0a9h,0adh,056h,078h,012h,004h,094h,0d8h,0b6h,04dh	; 7df3  .8......Vx.....M
	defb 049h,04ah,049h,04ah,0ach,0abh,0ach,0abh,058h,057h,078h,040h,041h,042h,043h,044h	; 7e03  IJIJ....XWx@ABCD
	defb 045h,00ch,004h,08eh,0d8h,0b7h,0b8h,04bh,04ch,04bh,04ch,0a9h,0aah,0a9h,0adh,059h	; 7e13  E......KLKL....Y
	defb 004h,07ah,012h,006h,08dh,0dah,004h,0b9h,04dh,04eh,04fh,049h,0abh,0ach,0abh,056h	; 7e23  .z......MNOI...V
	defb 004h,079h,014h,006h,08ch,0d9h,004h,0b6h,050h,051h,04bh,0aah,0a9h,05ah,057h,004h	; 7e33  .y......PQK..ZW.
	defb 07ah,003h,006h,081h,066h,005h,067h,082h,068h,0c8h,005h,067h,081h,0c6h,003h,006h	; 7e43  z...f.g.h..g....
	defb 08bh,0dah,004h,0b7h,052h,053h,04ah,0ach,0abh,059h,004h,079h,004h,006h,081h,069h	; 7e53  ....RSJ..Y.y...i
	defb 005h,00ch,082h,06ah,0cah,005h,00ch,081h,0c9h,004h,006h,08ah,0d9h,004h,0b9h,04bh	; 7e63  ...j...........K
	defb 04ch,0a9h,0b4h,004h,004h,07ah,003h,006h,081h,06bh,006h,00ch,082h,06ah,0cah,006h	; 7e73  L....z...k...j..
	defb 00ch,081h,0cbh,003h,006h,089h,0dah,004h,004h,054h,049h,0b5h,057h,004h,079h,004h	; 7e83  .........TI.W.y.
	defb 006h,081h,06ch,006h,00ch,082h,06ah,0cah,006h,00ch,081h,0cch,004h,006h,08dh,0d9h	; 7e93  ..l...j.........
	defb 004h,0b7h,055h,059h,004h,004h,07ah,006h,006h,05bh,063h,064h,006h,05fh,082h,061h	; 7ea3  ..UY..z..[cd._.a
	defb 0c1h,006h,05fh,08ch,0c4h,063h,0bbh,006h,006h,0dah,004h,004h,0b9h,004h,004h,079h	; 7eb3  .._..c.........y
	defb 003h,006h,083h,05ch,062h,069h,00eh,060h,083h,0c9h,0c2h,0bch,003h,006h,081h,0d9h	; 7ec3  ...\bi.`........
	defb 004h,004h,081h,07ah,003h,006h,082h,05dh,05eh,007h,00ch,082h,06ah,0cah,007h,00ch	; 7ed3  ...z...]^...j...
	defb 082h,0beh,0bdh,003h,006h,081h,0dah,003h,004h,081h,079h,005h,006h,081h,06ch,007h	; 7ee3  ..........y...l.
	defb 00ch,082h,06ah,0cah,007h,00ch,081h,0cch,005h,006h,084h,0d9h,004h,004h,07ah,003h	; 7ef3  ..j...........z.
	defb 047h,002h,006h,081h,06dh,007h,00ch,082h,06ah,0cah,007h,00ch,083h,0cdh,006h,006h	; 7f03  G...m...j.......
	defb 003h,047h,08ah,0dah,004h,079h,048h,09ch,065h,000h,0a8h,006h,069h,007h,00ch,082h	; 7f13  .G...yH.e...i...
	defb 06ah,0cah,007h,00ch,08ah,0c9h,006h,048h,09ch,065h,000h,0a8h,0d9h,07ah,048h,003h	; 7f23  j......H.e...zH.
	defb 000h,082h,0a8h,06bh,008h,00ch,082h,06ah,0cah,008h,00ch,082h,0cbh,048h,003h,000h	; 7f33  ...k...j.....H..
	defb 084h,0a8h,0dah,006h,089h,003h,046h,082h,0e9h,06ch,008h,00ch,082h,06ah,0cah,008h	; 7f43  ......F..l...j..
	defb 00ch,082h,0cch,089h,003h,046h,081h,0e9h,007h,006h,081h,06dh,008h,00ch,082h,06ah	; 7f53  .....F.....m...j
	defb 0cah,008h,00ch,081h,0cdh,00ch,006h,081h,069h,008h,00ch,082h,06ah,0cah,008h,00ch	; 7f63  ........i...j...
	defb 081h,0c9h,00bh,006h,081h,06eh,009h,06fh,082h,070h,0d0h,009h,06fh,081h,0ceh,00ah	; 7f73  .....n.o.p..o...
	defb 006h,084h,071h,072h,072h,073h,00eh,074h,084h,0d3h,072h,072h,0d1h,00dh,006h,081h	; 7f83  ..qrrs.t..rr....
	defb 075h,00eh,001h,081h,0d5h,010h,006h,081h,076h,00eh,001h,081h,0d6h,00fh,006h,081h	; 7f93  u.......v.......
	defb 077h,010h,001h,081h,0d7h,027h,006h,000h	; 7fa3  w....'..

; ----------------------------------------------------------------------
; DATOS relleno: 70 bytes a 0xFF, lo que quedaba libre del cartucho
;   0x7fab..0x7ff1  (70 bytes)
DATA_relleno:
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 7fab  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 7fbb  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 7fcb  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 7fdb  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 7feb

; ----------------------------------------------------------------------
; DATOS marca_oculta_de_konami: el titulo en katakana (12 bytes), su longitud
;   0x0C y el 0x31 de RC-731
;   0x7ff1..0x8000  (15 bytes)
DATA_marca_oculta_de_konami:
	defb 0ach	; 7ff1
	defb 0b8h	; 7ff2
	defb 09dh	; 7ff3
	defb 0ach	; 7ff4
	defb 0b8h	; 7ff5
	defb 09ah	; 7ff6
	defb 000h	; 7ff7
	defb 098h	; 7ff8
	defb 000h	; 7ff9
	defb 09fh	; 7ffa
	defb 094h	; 7ffb
	defb 089h	; 7ffc
	defb 00ch	; 7ffd
	defb 031h	; 7ffe
	defb 0aah	; 7fff
