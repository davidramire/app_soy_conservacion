import { PrismaClient } from '@prisma/client';
const prisma = new PrismaClient();

async function main() {
  const obs = await prisma.observacion.findMany({
    where: {
      latitud: { gt: 7, lt: 12 },
      longitud: { gt: -86, lt: -82 },
    },
    include: {
      especie: true,
      usuario: true,
      fuente: true,
    }
  });

  console.log("ODK Observations near Costa Rica:");
  console.dir(obs, { depth: null });
}

main()
  .catch(e => {
    console.error(e);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
