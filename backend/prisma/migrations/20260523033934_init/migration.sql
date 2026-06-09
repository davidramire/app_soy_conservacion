-- CreateTable
CREATE TABLE "usuarios" (
    "id_usuario" SERIAL NOT NULL,
    "username" TEXT NOT NULL,
    "fecha_registro" TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "usuarios_pkey" PRIMARY KEY ("id_usuario")
);

-- CreateTable
CREATE TABLE "grupo_taxonomico" (
    "id_grupo" SERIAL NOT NULL,
    "nombre" TEXT NOT NULL,

    CONSTRAINT "grupo_taxonomico_pkey" PRIMARY KEY ("id_grupo")
);

-- CreateTable
CREATE TABLE "especies" (
    "id_especie" SERIAL NOT NULL,
    "nombre_cientifico" TEXT NOT NULL,
    "grupo_taxonomico" INTEGER NOT NULL,

    CONSTRAINT "especies_pkey" PRIMARY KEY ("id_especie")
);

-- CreateTable
CREATE TABLE "fuente" (
    "id_fuente" SERIAL NOT NULL,
    "nombre" TEXT NOT NULL,

    CONSTRAINT "fuente_pkey" PRIMARY KEY ("id_fuente")
);

-- CreateTable
CREATE TABLE "observaciones" (
    "id_observacion" SERIAL NOT NULL,
    "id_usuario" INTEGER NOT NULL,
    "id_especie" INTEGER NOT NULL,
    "instance_id" TEXT NOT NULL,
    "fecha" TIMESTAMPTZ NOT NULL,
    "foto" TEXT,
    "audio" TEXT,
    "latitud" DOUBLE PRECISION,
    "longitud" DOUBLE PRECISION,
    "geom" TEXT,
    "altitude" DOUBLE PRECISION,
    "accuracy" DOUBLE PRECISION,
    "id_fuente" INTEGER NOT NULL,

    CONSTRAINT "observaciones_pkey" PRIMARY KEY ("id_observacion")
);

-- CreateTable
CREATE TABLE "inaturalist_observaciones" (
    "id_inaturalist_observacion" SERIAL NOT NULL,
    "id_usuario" INTEGER NOT NULL,
    "id_especie" INTEGER NOT NULL,
    "inaturalist_id" TEXT NOT NULL,
    "fecha" TIMESTAMPTZ NOT NULL,
    "foto" TEXT,
    "audio" TEXT,
    "latitud" DOUBLE PRECISION,
    "longitud" DOUBLE PRECISION,
    "geom" TEXT,
    "accuracy" DOUBLE PRECISION,
    "url_inaturalist" TEXT,
    "quality_grade" TEXT,
    "license" TEXT,
    "id_grupo" INTEGER NOT NULL,
    "id_fuente" INTEGER NOT NULL,

    CONSTRAINT "inaturalist_observaciones_pkey" PRIMARY KEY ("id_inaturalist_observacion")
);

-- CreateIndex
CREATE UNIQUE INDEX "usuarios_username_key" ON "usuarios"("username");

-- CreateIndex
CREATE UNIQUE INDEX "grupo_taxonomico_nombre_key" ON "grupo_taxonomico"("nombre");

-- CreateIndex
CREATE UNIQUE INDEX "especies_nombre_cientifico_key" ON "especies"("nombre_cientifico");

-- CreateIndex
CREATE INDEX "especies_grupo_taxonomico_idx" ON "especies"("grupo_taxonomico");

-- CreateIndex
CREATE UNIQUE INDEX "fuente_nombre_key" ON "fuente"("nombre");

-- CreateIndex
CREATE UNIQUE INDEX "observaciones_instance_id_key" ON "observaciones"("instance_id");

-- CreateIndex
CREATE INDEX "observaciones_id_usuario_idx" ON "observaciones"("id_usuario");

-- CreateIndex
CREATE INDEX "observaciones_id_especie_idx" ON "observaciones"("id_especie");

-- CreateIndex
CREATE INDEX "observaciones_id_fuente_idx" ON "observaciones"("id_fuente");

-- CreateIndex
CREATE INDEX "observaciones_fecha_idx" ON "observaciones"("fecha");

-- CreateIndex
CREATE INDEX "observaciones_lat_lng_idx" ON "observaciones"("latitud", "longitud");

-- CreateIndex
CREATE INDEX "observaciones_fecha_lat_lng_idx" ON "observaciones"("fecha", "latitud", "longitud");

-- CreateIndex
CREATE UNIQUE INDEX "inaturalist_observaciones_inaturalist_id_key" ON "inaturalist_observaciones"("inaturalist_id");

-- CreateIndex
CREATE INDEX "inaturalist_observaciones_id_usuario_idx" ON "inaturalist_observaciones"("id_usuario");

-- CreateIndex
CREATE INDEX "inaturalist_observaciones_id_especie_idx" ON "inaturalist_observaciones"("id_especie");

-- CreateIndex
CREATE INDEX "inaturalist_observaciones_id_grupo_idx" ON "inaturalist_observaciones"("id_grupo");

-- CreateIndex
CREATE INDEX "inaturalist_observaciones_id_fuente_idx" ON "inaturalist_observaciones"("id_fuente");

-- CreateIndex
CREATE INDEX "inaturalist_observaciones_fecha_idx" ON "inaturalist_observaciones"("fecha");

-- CreateIndex
CREATE INDEX "inaturalist_observaciones_lat_lng_idx" ON "inaturalist_observaciones"("latitud", "longitud");

-- CreateIndex
CREATE INDEX "inaturalist_observaciones_fecha_lat_lng_idx" ON "inaturalist_observaciones"("fecha", "latitud", "longitud");

-- AddForeignKey
ALTER TABLE "especies" ADD CONSTRAINT "especies_grupo_taxonomico_fkey" FOREIGN KEY ("grupo_taxonomico") REFERENCES "grupo_taxonomico"("id_grupo") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "observaciones" ADD CONSTRAINT "observaciones_id_usuario_fkey" FOREIGN KEY ("id_usuario") REFERENCES "usuarios"("id_usuario") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "observaciones" ADD CONSTRAINT "observaciones_id_especie_fkey" FOREIGN KEY ("id_especie") REFERENCES "especies"("id_especie") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "observaciones" ADD CONSTRAINT "observaciones_id_fuente_fkey" FOREIGN KEY ("id_fuente") REFERENCES "fuente"("id_fuente") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "inaturalist_observaciones" ADD CONSTRAINT "inaturalist_observaciones_id_usuario_fkey" FOREIGN KEY ("id_usuario") REFERENCES "usuarios"("id_usuario") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "inaturalist_observaciones" ADD CONSTRAINT "inaturalist_observaciones_id_especie_fkey" FOREIGN KEY ("id_especie") REFERENCES "especies"("id_especie") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "inaturalist_observaciones" ADD CONSTRAINT "inaturalist_observaciones_id_grupo_fkey" FOREIGN KEY ("id_grupo") REFERENCES "grupo_taxonomico"("id_grupo") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "inaturalist_observaciones" ADD CONSTRAINT "inaturalist_observaciones_id_fuente_fkey" FOREIGN KEY ("id_fuente") REFERENCES "fuente"("id_fuente") ON DELETE RESTRICT ON UPDATE CASCADE;
