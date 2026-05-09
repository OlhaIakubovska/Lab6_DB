import * as dotenv from 'dotenv';
dotenv.config();
import { PrismaPg } from '@prisma/adapter-pg';
import { PrismaClient } from '@prisma/client';

const adapter = new PrismaPg({ connectionString: process.env.DATABASE_URL });
const prisma = new PrismaClient({ adapter });

async function main() {
    // 1. Вставити сертифікат для студента який завершив курс
    const cert = await prisma.certificate.create({
        data: {
            studentid: 19,
            courseid: 21,
            issuedate: new Date('2024-06-15')
        }
    });
    console.log('Створено сертифікат:', cert);

    // 2. Опублікувати курс
    const updatedCourse = await prisma.course.update({
        where: { courseid: 21 },
        data: { ispublished: true }
    });
    console.log('Оновлено курс:', updatedCourse.title, '| ispublished:', updatedCourse.ispublished);

    // 3. Запросити всі сертифікати
    const certificates = await prisma.certificate.findMany({
        include: {
            student: { include: { User: true } },
            course: true
        }
    });
    console.log('\nВсі сертифікати:');
    certificates.forEach(c => {
        console.log(`- ${c.student.User.firstname} ${c.student.User.lastname} | Курс: ${c.course.title} | Дата: ${c.issuedate}`);
    });

    // 4. Запросити опубліковані курси
    const publishedCourses = await prisma.course.findMany({
        where: { ispublished: true }
    });
    console.log('\nОпубліковані курси:');
    publishedCourses.forEach(c => console.log(`- ${c.title}`));
}

main()
    .catch(console.error)
    .finally(() => prisma.$disconnect());