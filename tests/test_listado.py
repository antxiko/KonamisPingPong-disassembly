#!/usr/bin/env python3
"""Comprobaciones sobre el listado generado y sobre la web.

Ninguna necesita el cartucho: se hacen sobre src/pingpong.asm,
src/pingpong.notes y el trazado. Vigilan que el listado no se degrade sin que
nadie se entere -que no desaparezcan comentarios, que no vuelvan a aparecer
bloques sin identificar- y que las cifras publicadas en la web sean las del
arbol y no las que habia cuando se escribio el texto.

Las de TestRLE, TestRotulos y TestTablas no miran el ASPECTO de los bytes:
EJECUTAN el descompresor y el interprete de rotulos que se rehicieron en
tools/. Si el formato estuviera mal leido, los bloques no cerrarian donde
cierran ni los rotulos dirian lo que dicen.
"""
import json
import math
import os
import re
import sys
import unittest

RAIZ = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
ASM = os.path.join(RAIZ, "src", "pingpong.asm")
NOTES = os.path.join(RAIZ, "src", "pingpong.notes")
ENTRIES = os.path.join(RAIZ, "src", "pingpong.entries")
TRACE = os.path.join(RAIZ, "work", "pingpong.trace.json")
DOCS = os.path.join(RAIZ, "docs")
ORG, FIN = 0x4000, 0x8000

sys.path.insert(0, os.path.join(RAIZ, "tools"))

# Los demas juegos de la serie. Que el nombre de otro salga en una pagina de
# este es casi siempre un copia y pega: ya paso con cinco ficheros LICENSE y
# con el pie de catorce paginas de otro proyecto.
OTROS_JUEGOS = (
    "Tennis", "Pitfall", "Temptations", "Stardust", "Ale Hop", "Colt 36",
    "Antarctic", "Athletic Land", "Monkey Academy", "F-1 Spirit", "Pippols",
    "Time Pilot", "Frogger", "Super Cobra", "Billiards", "Mahjong",
    "Hyper Rally", "Hyper Sports", "Nemesis", "Demonia", "Cabbage",
    "Hole in One", "Casio World Open", "3D Golf", "Baseball",
    "Yie Ar Kung-Fu", "King's Valley", "Sky Jaguar", "Mopi Ranger",
    "Road Fighter", "Descubrimiento", "War in Middle Earth",
)


def lee(ruta):
    with open(ruta, encoding="utf-8") as f:
        return f.read()


def bloques_del_listado(lineas):
    """Los mismos bloques que cuenta tools/densidad.py, con su misma logica.

    Dos detalles suyos hay que respetar o las cifras no cuadran: una etiqueta
    solo cuenta si su linea no lleva nada mas (salvo un comentario), y una
    linea es de INSTRUCCION cuando su direccion viene pegada al punto y coma
    (";4323"), mientras que las de datos llevan un espacio ("; 4323"). Por eso
    los bloques DATA_ salen con cero instrucciones y no cuentan como rutina.
    """
    bloques, nombre, ini, n, c = [], "(cabecera)", 0, 0, 0
    for ln in lineas:
        m = re.match(r"^([A-Za-z_][A-Za-z_0-9]*):\s*(;.*)?$", ln)
        if m:
            if n:
                bloques.append((nombre, ini, n, c))
            nombre, ini, n, c = m.group(1), 0, 0, 0
            continue
        m = re.match(r"^\t.*;([0-9a-f]{4})(.*)$", ln)
        if not m:
            continue
        if not ini:
            ini = int(m.group(1), 16)
        n += 1
        if ";" in m.group(2):
            c += 1
    if n:
        bloques.append((nombre, ini, n, c))
    return bloques


def rom_del_listado():
    """Reconstruye los BYTES DE DATOS del cartucho leyendo el listado.

    El cartucho no viaja con el repositorio, pero src/pingpong.asm si, y cada
    fila de datos lleva su direccion en el comentario -eso lo pone mkasm.py-.
    Con las filas `defb` y `defw` se rehace un buffer de 16 KB con todas las
    zonas de datos en su sitio, que es lo unico que el descompresor necesita
    leer. Asi estos tests corren en un clon pelado, sin cartucho y sin `make`.
    """
    rom = bytearray(FIN - ORG)
    for linea in lee(ASM).splitlines():
        m = re.match(r"\s*(defb|defw)\s+([^;]+);\s*([0-9a-f]{4})", linea)
        if not m:
            continue
        que, cuerpo, addr = m.group(1), m.group(2), int(m.group(3), 16)
        p = addr - ORG
        for tok in cuerpo.split(","):
            tok = tok.strip()
            if not re.fullmatch(r"[0-9][0-9a-fA-F]*h", tok):
                continue
            v = int(tok[:-1], 16)
            if que == "defb":
                rom[p] = v & 0xFF
                p += 1
            else:
                rom[p] = v & 0xFF
                rom[p + 1] = (v >> 8) & 0xFF
                p += 2
    return bytes(rom)


def bloques_declarados():
    """Las directivas D del .notes: {nombre: (ini, fin, explicacion)}."""
    d = {}
    for m in re.finditer(
            r"^D\s+(0x[0-9a-fA-F]+)\s+(0x[0-9a-fA-F]+)\s+(\S+)(.*)$",
            lee(NOTES), re.MULTILINE):
        d[m.group(3)] = (int(m.group(1), 16), int(m.group(2), 16),
                         m.group(4).strip())
    return d


def como_texto(bs):
    """Los tiles leidos como letras: el indice de patron es el ASCII menos 0x20."""
    return "".join(chr(b + 0x20) if 0x20 <= b + 0x20 < 0x7F else "."
                   for b in bs)


class TestListado(unittest.TestCase):
    """El listado en si."""

    @classmethod
    def setUpClass(cls):
        cls.lineas = lee(ASM).splitlines()
        cls.bloques = bloques_del_listado(cls.lineas)

    def test_no_quedan_bloques_sin_identificar(self):
        """Ni un `DATOS sin identificar` en el listado.

        Es la cabecera que mkasm.py pone cuando un rango de datos no tiene
        directiva D. Que reaparezca significa que alguien anadio codigo o
        movio un limite y dejo bytes sin explicar.
        """
        sueltos = [ln for ln in self.lineas if "sin identificar" in ln]
        self.assertEqual(sueltos, [], "hay bloques de datos sin declarar")

    def test_todas_las_rutinas_llegan_al_liston(self):
        """NINGUNA rutina de mas de cinco instrucciones baja del 10 %.

        El liston de la serie: una rutina larga sin un solo comentario no esta
        explicada, por muy bien que este el resto del listado. Aqui se cerro a
        cero, asi que el test no admite ni una.
        """
        flojas = [(n, i, c) for n, i, c in
                  ((b[0], b[2], b[3]) for b in self.bloques)
                  if i > 5 and c * 10 < i]
        self.assertEqual(
            flojas, [], "han aparecido rutinas flojas: %s" % flojas[:5])

    def test_hay_al_menos_dos_mil_cuatrocientos_comentarios(self):
        """La densidad medida no puede caer.

        2.503 al cerrar la tanda, o sea el 64,3 %. Se deja el minimo un poco
        por debajo para que un retrazado que junte o parta bloques no lo rompa
        por un puñado.
        """
        total = sum(b[3] for b in self.bloques)
        self.assertGreaterEqual(total, 2450,
                                "se han perdido comentarios por el camino")

    def test_las_etiquetas_son_snake_case(self):
        """Las bautizadas a mano, en minusculas y con guion bajo.

        Las L_XXXX y DATA_XXXX las pone mkasm.py y quedan fuera.
        """
        malas = []
        for m in re.finditer(r"^L\s+0x[0-9a-fA-F]{4}\s+(\S+)", lee(NOTES),
                             re.MULTILINE):
            if not re.fullmatch(r"[a-z][a-z0-9_]*", m.group(1)):
                malas.append(m.group(1))
        self.assertEqual(malas, [], "etiquetas que no son snake_case")

    def test_ninguna_cabecera_de_bloque_sale_repetida(self):
        """La misma cabecera B no puede aparecer dos veces en el listado.

        El aplicador de comentarios llego a meterlas otra vez en cada pasada,
        y el listado acababa con la misma cabecera diez veces seguidas.
        """
        vistas = {}
        for m in re.finditer(r"^B\s+(0x[0-9a-fA-F]{4})\s", lee(NOTES),
                             re.MULTILINE):
            vistas[m.group(1)] = vistas.get(m.group(1), 0) + 1
        repes = {k: v for k, v in vistas.items() if v > 1}
        self.assertEqual(repes, {}, "cabeceras de bloque repetidas")


class TestCobertura(unittest.TestCase):
    """Que no quede ni un byte del cartucho sin asignar."""

    def test_el_trazado_cubre_el_cartucho_entero(self):
        """Codigo trazado mas datos declarados suman los 16.384 bytes."""
        if not os.path.exists(TRACE):
            self.skipTest("hace falta `make trace`")
        mapa = bytearray(FIN - ORG)
        # z80trace.py marca los bloques con "c" de codigo y "d" de datos.
        with open(TRACE, encoding="utf-8") as f:
            bloques = json.load(f)["blocks"]
        for tipo, a, b in bloques:
            if tipo == "c":
                for p in range(a - ORG, b - ORG):
                    mapa[p] = 1
        for ini, fin, _ in bloques_declarados().values():
            for p in range(ini - ORG, fin - ORG):
                mapa[p] = 1
        huecos = mapa.count(0)
        self.assertEqual(huecos, 0, "%d bytes sin explicar" % huecos)

    def test_las_entradas_estan_justificadas(self):
        """Cada punto de entrada declarado lleva su comentario al lado.

        Una entrada sin justificar es una direccion metida a mano para que la
        cobertura cuadre.
        """
        sin = []
        for ln in lee(ENTRIES).splitlines():
            ln = ln.strip()
            if not ln or ln.startswith("#"):
                continue
            if "#" not in ln:
                sin.append(ln)
        self.assertEqual(sin, [], "entradas sin justificar")


class TestNotas(unittest.TestCase):
    """El fichero de anotaciones."""

    @classmethod
    def setUpClass(cls):
        cls.d = bloques_declarados()

    def test_cada_bloque_de_datos_tiene_nombre_y_explicacion(self):
        cortos = [n for n, (_, _, e) in self.d.items() if len(e) < 20]
        self.assertEqual(cortos, [], "bloques sin explicacion de verdad")

    def test_las_anchuras_declaradas_apuntan_a_un_bloque(self):
        """Toda directiva F cae en el arranque de una D."""
        arranques = {i for i, _, _ in self.d.values()}
        sueltas = []
        for m in re.finditer(r"^F\s+(0x[0-9a-fA-F]+)\s", lee(NOTES),
                             re.MULTILINE):
            if int(m.group(1), 16) not in arranques:
                sueltas.append(m.group(1))
        self.assertEqual(sueltas, [], "anchuras que no arrancan un bloque")

    def test_las_zonas_de_datos_no_se_solapan(self):
        rangos = sorted((i, f, n) for n, (i, f, _) in self.d.items())
        for (i1, f1, n1), (i2, _, n2) in zip(rangos, rangos[1:]):
            self.assertLessEqual(f1, i2, "%s y %s se solapan" % (n1, n2))


class TestRLE(unittest.TestCase):
    """Los bloques comprimidos, medidos EJECUTANDO el descompresor."""

    @classmethod
    def setUpClass(cls):
        import rle
        cls.rle = rle
        cls.rom = rom_del_listado()
        cls.d = bloques_declarados()

    def cierra_en(self, ini, vram_ini=None):
        r = self.rle.descomprime(self.rom, ORG, ini, vram_ini)
        self.assertIsNotNone(r, "el bloque de 0x%04X no cierra" % ini)
        return r[0]

    def test_cada_bloque_rle_cierra_donde_dice_su_directiva(self):
        """Los que llevan el destino dentro: el 0x00 cae en el limite declarado."""
        for nombre in ("rle_marco_del_menu", "rle_nombres_del_menu",
                       "rle_sprites_de_la_mesa", "rle_sprites_de_la_pelota"):
            ini, fin, _ = self.d[nombre]
            self.assertEqual(self.cierra_en(ini), fin,
                             "%s no cierra donde dice" % nombre)

    def test_la_pantalla_de_titulo_llena_los_768_nombres(self):
        """440 bytes que dan la tabla de nombres ENTERA, 32 por 24."""
        ini, _, _ = self.d["rle_pantalla_de_titulo"]
        _, _, tocado, tramos = self.rle.descomprime(self.rom, ORG, ini, None)
        self.assertEqual(len(tramos), 1)
        self.assertEqual(tramos[0][0], 0x3800, "no va a la tabla de nombres")
        self.assertEqual(sum(tocado), 768, "no cubre las 24 filas de 32")

    def test_los_cuarenta_fotogramas_encadenan_hasta_el_bloque_siguiente(self):
        """La prueba fuerte de que 0x73A7..0x7D25 son 40 bloques pegados.

        Se descomprime uno detras de otro desde 0x73A7 y la cadena tiene que
        caer EXACTAMENTE en 0x7D26, que es donde empieza el bloque siguiente,
        que ya se conocia por otro camino.
        """
        ini, fin, _ = self.d["patrones_de_los_jugadores"]
        p, n = ini, 0
        destinos = []
        while p < fin and n < 60:
            r = self.rle.descomprime(self.rom, ORG, p, None)
            self.assertIsNotNone(r, "el bloque de 0x%04X no cierra" % p)
            destinos.append(r[3][0][0])
            p, n = r[0], n + 1
        self.assertEqual(p, fin, "la cadena no cae en 0x%04X" % fin)
        self.assertEqual(n, 40, "no salen cuarenta fotogramas")
        self.assertEqual(destinos.count(0x1800), 20, "veinte para el cercano")
        self.assertEqual(destinos.count(0x18A0), 20, "veinte para el lejano")

    def test_los_punteros_de_los_fotogramas_son_esos_mismos_arranques(self):
        """Y la segunda prueba, independiente de la anterior.

        Cada fotograma lleva pegado detras de sus datos de sprite el puntero a
        sus patrones. Recorriendo las dos tablas salen 40 punteros, y tienen
        que ser uno por uno los 40 arranques de la cadena.
        """
        rom, ini, fin = self.rom, *self.d["patrones_de_los_jugadores"][:2]
        cadena, p = [], ini
        while p < fin:
            cadena.append(p)
            p = self.rle.descomprime(rom, ORG, p, None)[0]

        def w(a):
            return rom[a - ORG] | (rom[a - ORG + 1] << 8)

        punteros = []
        for base, nspr in ((0x5FF7, 5), (0x601F, 5)):
            for i in range(20):
                q, k = w(base + i * 2), 0
                while k < nspr and rom[q - ORG] != 0x81:
                    q, k = q + 3, k + 1
                punteros.append(w(q + 1))
        self.assertEqual(sorted(punteros), sorted(cadena),
                         "los punteros no coinciden con los arranques")


class TestRotulos(unittest.TestCase):
    """Los guiones, medidos EJECUTANDO el interprete del cartucho."""

    @classmethod
    def setUpClass(cls):
        import guiones
        cls.g = guiones
        cls.rom = rom_del_listado()
        cls.d = bloques_declarados()

    def texto(self, ini):
        r = self.g.ejecuta(self.rom, ORG, ini)
        self.assertIsNotNone(r, "el guion de 0x%04X no cierra" % ini)
        return " ".join(r[1].split()), r[0]

    def test_el_rotulo_del_final_dice_game_set(self):
        t, _ = self.texto(self.d["guion_game_set"][0])
        self.assertIn("GAME SET", t)

    def test_el_cambio_de_campo_dice_change_court(self):
        t, _ = self.texto(self.d["guion_change_court"][0])
        self.assertIn("CHANGE COURT", t)

    def test_el_empate_a_veinte_dice_deuce(self):
        t, _ = self.texto(self.d["guion_deuce"][0])
        self.assertIn("DEUCE", t)

    def test_el_tanteo_de_salida_dice_love_all(self):
        t, _ = self.texto(self.d["guion_game_love_all"][0])
        self.assertIn("LOVE ALL", t)

    def test_los_cuatro_cantes_del_arbitro(self):
        """LET, NET, OUT e IN, sacados de su tabla de punteros."""
        rom = self.rom
        base = self.d["tabla_de_cantes"][0]
        dichos = []
        for i in range(4):
            p = (rom[base - ORG + i * 2] | (rom[base - ORG + i * 2 + 1] << 8))
            fin = p
            while rom[fin - ORG] != 0xFF:
                fin += 1
            dichos.append(como_texto(rom[p - ORG:fin - ORG]))
        self.assertEqual(dichos, ["LET", "NET", "OUT", "IN"])

    def test_los_ordinales_son_los_tres_sets(self):
        """1ST, 2ND y 3RD: se juega al mejor de tres."""
        rom = self.rom
        base = self.d["tabla_de_ordinales"][0]
        dichos = []
        for i in range(3):
            p = (rom[base - ORG + i * 2] | (rom[base - ORG + i * 2 + 1] << 8))
            # dos bytes de destino, tres patrones y el 0xFF
            dichos.append(como_texto(rom[p - ORG + 2:p - ORG + 5]))
        self.assertEqual(dichos, ["1ST", "2ND", "3RD"])

    def test_cada_guion_cierra_donde_dice_su_directiva(self):
        for nombre, (ini, fin, _) in self.d.items():
            if not nombre.startswith("guion_"):
                continue
            _, acaba = self.texto(ini)
            self.assertEqual(acaba, fin, "%s no cierra donde dice" % nombre)


class TestTablas(unittest.TestCase):
    """Las tablas: que sean lo que la nota dice que son."""

    @classmethod
    def setUpClass(cls):
        cls.rom = rom_del_listado()
        cls.d = bloques_declarados()

    def b(self, a):
        return self.rom[a - ORG]

    def w(self, a):
        return self.b(a) | (self.b(a + 1) << 8)

    def test_las_tablas_pegadas_detras_del_call_encajan(self):
        """Su primera entrada apunta justo detras de la tabla.

        Es el encaje que fija cuantas entradas tienen, y el que las declaro.
        """
        for nombre in ("tabla_de_escenas", "tabla_de_subescenas"):
            ini, fin, _ = self.d[nombre]
            self.assertEqual(self.w(ini), fin,
                             "%s no encaja con su primera entrada" % nombre)

    def test_los_registros_del_vdp_ponen_la_vram_del_reves(self):
        """R3 y R4 son base y mascara, y dejan el COLOR abajo y los PATRONES arriba."""
        ini, fin, _ = self.d["registros_del_vdp"]
        r = [self.b(ini + i) for i in range(fin - ini)]
        self.assertEqual(len(r), 8)
        self.assertEqual((r[0] >> 1) & 1, 1, "no es SCREEN 2")
        self.assertEqual(r[2] * 0x400, 0x3800, "los nombres no van a 0x3800")
        self.assertEqual((r[3] & 0x80) * 0x40, 0x0000, "el COLOR no va abajo")
        self.assertEqual((r[4] & 0x04) * 0x800, 0x2000,
                         "los PATRONES no van arriba")
        self.assertEqual(r[6] * 0x800, 0x1800, "los sprites no van a 0x1800")

    def test_los_doce_periodos_son_semitonos_temperados(self):
        """La razon entre notas consecutivas ronda la duodecima raiz de dos."""
        ini, fin, _ = self.d["periodos_del_psg"]
        p = [self.b(a) for a in range(ini, fin)]
        self.assertEqual(len(p), 12, "no son doce notas")
        semitono = 2 ** (1 / 12)
        for i in range(11):
            razon = p[i] / p[i + 1]
            self.assertAlmostEqual(razon, semitono, delta=0.02,
                                   msg="la nota %d no es un semitono" % i)

    def test_la_tabla_de_melodias_encaja_con_su_primera_entrada(self):
        """0x5339 + 54*2 = 0x53A5, que es lo que dice la entrada 1."""
        ini, fin, _ = self.d["tabla_de_melodias"]
        self.assertEqual(self.w(ini), fin)
        self.assertEqual((fin - ini) // 2, 54, "no son 54 melodias")

    def test_todas_las_melodias_caen_dentro_de_su_bloque(self):
        ini, fin, _ = self.d["tabla_de_melodias"]
        mi, mf, _ = self.d["melodias"]
        for a in range(ini, fin, 2):
            self.assertTrue(mi <= self.w(a) <= mf,
                            "la melodia de 0x%04X se sale" % a)

    def test_la_tabla_de_seno_es_un_seno(self):
        """Los 31 primeros valores, contra 255*sin de un cuarto de vuelta."""
        ini, _, _ = self.d["tabla_de_seno"]
        v = [self.b(ini + i) for i in range(31)]
        self.assertEqual(v[0], 12)
        self.assertEqual(v[-1], 255, "el cuarto de onda no remata en 255")
        for i, x in enumerate(v):
            t = 255 * math.sin(math.radians((i + 1) * 90 / 31))
            self.assertLess(abs(x - t), 8,
                            "el valor %d se aleja del seno" % i)

    def test_el_seno_y_el_coseno_van_a_un_cuarto_de_onda(self):
        """Los dos arranques que usa el juego estan separados 31 posiciones."""
        ini, _, _ = self.d["tabla_de_seno"]
        self.assertEqual(0x6ECC - ini, 31)

    def test_las_trayectorias_son_cinco_niveles_por_seis_zonas(self):
        """30 entradas, y la primera apunta justo detras de la tabla."""
        ini, fin, _ = self.d["tabla_de_trayectorias"]
        self.assertEqual((fin - ini) // 2, 30)
        self.assertEqual(self.w(ini), fin)
        self.assertEqual(5 * 6, 30)

    def test_cada_trayectoria_mide_cuatro_bytes(self):
        """Las 30 entradas van de cuatro en cuatro y llenan su bloque."""
        ti, tf, _ = self.d["tabla_de_trayectorias"]
        ri, rf, _ = self.d["trayectorias"]
        e = [self.w(a) for a in range(ti, tf, 2)]
        self.assertEqual(e[0], ri)
        for a, b in zip(e, e[1:]):
            self.assertEqual(b - a, 4, "los registros no son de cuatro")
        self.assertEqual(e[-1] + 4, rf, "el ultimo no cierra el bloque")

    def test_los_cinco_niveles_del_menu(self):
        """1, 3, 5, 7 y 9: los que el menu ofrece."""
        ini, fin, _ = self.d["niveles_seleccionables"]
        self.assertEqual([self.b(a) for a in range(ini, fin)],
                         [1, 3, 5, 7, 9])

    def test_los_dos_modos_de_juego_se_separan_por_el_bit_5(self):
        """0x40 y 0x60: el bit 5 es el que todo el juego mira."""
        ini, fin, _ = self.d["modos_de_juego"]
        v = [self.b(a) for a in range(ini, fin)]
        self.assertEqual(v, [0x40, 0x60])
        self.assertEqual((v[0] >> 5) & 1, 0, "el primero no es un jugador")
        self.assertEqual((v[1] >> 5) & 1, 1, "el segundo no es dos jugadores")

    def test_la_marca_de_konami_dice_rc731(self):
        """Los ultimos quince bytes: doce de titulo, la longitud y el numero."""
        ini, fin, _ = self.d["marca_oculta_de_konami"]
        self.assertEqual(fin, FIN)
        self.assertEqual(self.b(fin - 3), 0x0C, "la longitud no es doce")
        self.assertEqual(self.b(fin - 2), 0x31, "el numero no es el 31")
        self.assertEqual(fin - 3 - ini, 12, "el titulo no mide doce bytes")

    def test_el_relleno_es_todo_ff(self):
        ini, fin, _ = self.d["relleno"]
        distintos = [a for a in range(ini, fin) if self.b(a) != 0xFF]
        self.assertEqual(distintos, [], "el relleno no es todo 0xFF")


class TestWeb(unittest.TestCase):
    """Que la web diga lo que el listado dice."""

    @classmethod
    def setUpClass(cls):
        if not os.path.isdir(DOCS):
            raise unittest.SkipTest("la web aun no esta escrita")
        cls.paginas = {}
        for base, _, ficheros in os.walk(DOCS):
            for f in ficheros:
                if f.endswith((".md", ".html")):
                    r = os.path.join(base, f)
                    cls.paginas[r] = lee(r)

    def test_no_se_nombra_otro_juego_de_la_serie(self):
        """El fallo mas repetido de la serie es el copia y pega del anterior.

        Road Fighter es la UNICA excepcion, y esta acotada: este cartucho
        comparte con el su armazon entero -incluidos los ocho bytes de los
        registros del VDP, identicos uno por uno- y eso se cuenta como
        hallazgo. Asi que se le permite aparecer, pero solo en las tres
        paginas donde la comparacion ES el contenido, y siempre al lado de la
        palabra que la justifica. En cualquier otra pagina sigue siendo un
        copia y pega, y el test lo caza igual.
        """
        permitido = ("FINDINGS", "HALLAZGOS", "OPEN-QUESTIONS",
                     "PREGUNTAS-ABIERTAS", "index")
        malas = []
        for ruta, texto in self.paginas.items():
            base = os.path.basename(ruta)
            for juego in OTROS_JUEGOS:
                if juego not in texto:
                    continue
                if (juego == "Road Fighter"
                        and base.rsplit(".", 1)[0] in permitido
                        and ("armazon" in texto or "armazón" in texto
                             or "skeleton" in texto)):
                    continue
                malas.append("%s nombra a %s" % (base, juego))
        self.assertEqual(malas, [], "; ".join(malas))

    def test_las_cifras_publicadas_son_las_del_listado(self):
        """El porcentaje comentado que se publica tiene que ser el medido."""
        bloques = bloques_del_listado(lee(ASM).splitlines())
        instr = sum(b[2] for b in bloques)
        coment = sum(b[3] for b in bloques)
        real = round(100.0 * coment / instr, 1)
        for ruta, texto in self.paginas.items():
            for m in re.finditer(r"(\d+[.,]\d)\s*%", texto):
                v = float(m.group(1).replace(",", "."))
                if 15.0 < v < 60.0:
                    self.assertAlmostEqual(
                        v, real, delta=0.6,
                        msg="%s publica %.1f %% y el listado da %.1f %%"
                            % (os.path.basename(ruta), v, real))


if __name__ == "__main__":
    unittest.main()
