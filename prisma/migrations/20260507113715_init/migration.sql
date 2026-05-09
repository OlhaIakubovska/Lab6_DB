-- CreateTable
CREATE TABLE "User" (
    "userid" SERIAL NOT NULL,
    "firstname" VARCHAR(50) NOT NULL,
    "lastname" VARCHAR(50) NOT NULL,
    "email" VARCHAR(100) NOT NULL,
    "password" VARCHAR(255) NOT NULL,
    "registrationdate" DATE NOT NULL DEFAULT CURRENT_DATE,

    CONSTRAINT "User_pkey" PRIMARY KEY ("userid")
);

-- CreateTable
CREATE TABLE "course" (
    "courseid" SERIAL NOT NULL,
    "title" VARCHAR(150) NOT NULL,
    "description" TEXT,
    "price" DECIMAL(8,2) NOT NULL DEFAULT 0,
    "instructorid" INTEGER NOT NULL,

    CONSTRAINT "course_pkey" PRIMARY KEY ("courseid")
);

-- CreateTable
CREATE TABLE "enrollment" (
    "enrollmentid" SERIAL NOT NULL,
    "studentid" INTEGER NOT NULL,
    "courseid" INTEGER NOT NULL,
    "enrolldate" DATE NOT NULL DEFAULT CURRENT_DATE,
    "progress" DECIMAL(5,2) NOT NULL DEFAULT 0,

    CONSTRAINT "enrollment_pkey" PRIMARY KEY ("enrollmentid")
);

-- CreateTable
CREATE TABLE "expertisearea" (
    "expertiseid" SERIAL NOT NULL,
    "expertisename" VARCHAR(100) NOT NULL,

    CONSTRAINT "expertisearea_pkey" PRIMARY KEY ("expertiseid")
);

-- CreateTable
CREATE TABLE "instructor" (
    "userid" INTEGER NOT NULL,
    "bio" TEXT,
    "expertiseid" INTEGER NOT NULL,
    "rating" DECIMAL(3,2),

    CONSTRAINT "instructor_pkey" PRIMARY KEY ("userid")
);

-- CreateTable
CREATE TABLE "module" (
    "moduleid" SERIAL NOT NULL,
    "courseid" INTEGER NOT NULL,
    "title" VARCHAR(150) NOT NULL,
    "ordernumber" INTEGER NOT NULL,
    "contenturl" VARCHAR(255),

    CONSTRAINT "module_pkey" PRIMARY KEY ("moduleid")
);

-- CreateTable
CREATE TABLE "review" (
    "reviewid" SERIAL NOT NULL,
    "courseid" INTEGER NOT NULL,
    "studentid" INTEGER NOT NULL,
    "rating" INTEGER NOT NULL,
    "commenttext" TEXT,
    "reviewdate" DATE NOT NULL DEFAULT CURRENT_DATE,

    CONSTRAINT "review_pkey" PRIMARY KEY ("reviewid")
);

-- CreateTable
CREATE TABLE "student" (
    "userid" INTEGER NOT NULL,
    "academiclevel" VARCHAR(50) NOT NULL,
    "totalpoints" INTEGER NOT NULL DEFAULT 0,

    CONSTRAINT "student_pkey" PRIMARY KEY ("userid")
);

-- CreateIndex
CREATE UNIQUE INDEX "User_email_key" ON "User"("email");

-- CreateIndex
CREATE UNIQUE INDEX "enrollment_studentid_courseid_key" ON "enrollment"("studentid", "courseid");

-- CreateIndex
CREATE UNIQUE INDEX "expertisearea_expertisename_key" ON "expertisearea"("expertisename");

-- CreateIndex
CREATE UNIQUE INDEX "module_courseid_ordernumber_key" ON "module"("courseid", "ordernumber");

-- CreateIndex
CREATE UNIQUE INDEX "review_studentid_courseid_key" ON "review"("studentid", "courseid");

-- AddForeignKey
ALTER TABLE "course" ADD CONSTRAINT "course_instructorid_fkey" FOREIGN KEY ("instructorid") REFERENCES "instructor"("userid") ON DELETE RESTRICT ON UPDATE NO ACTION;

-- AddForeignKey
ALTER TABLE "enrollment" ADD CONSTRAINT "enrollment_courseid_fkey" FOREIGN KEY ("courseid") REFERENCES "course"("courseid") ON DELETE CASCADE ON UPDATE NO ACTION;

-- AddForeignKey
ALTER TABLE "enrollment" ADD CONSTRAINT "enrollment_studentid_fkey" FOREIGN KEY ("studentid") REFERENCES "student"("userid") ON DELETE CASCADE ON UPDATE NO ACTION;

-- AddForeignKey
ALTER TABLE "instructor" ADD CONSTRAINT "instructor_expertiseid_fkey" FOREIGN KEY ("expertiseid") REFERENCES "expertisearea"("expertiseid") ON DELETE NO ACTION ON UPDATE NO ACTION;

-- AddForeignKey
ALTER TABLE "instructor" ADD CONSTRAINT "instructor_userid_fkey" FOREIGN KEY ("userid") REFERENCES "User"("userid") ON DELETE CASCADE ON UPDATE NO ACTION;

-- AddForeignKey
ALTER TABLE "module" ADD CONSTRAINT "module_courseid_fkey" FOREIGN KEY ("courseid") REFERENCES "course"("courseid") ON DELETE CASCADE ON UPDATE NO ACTION;

-- AddForeignKey
ALTER TABLE "review" ADD CONSTRAINT "review_courseid_fkey" FOREIGN KEY ("courseid") REFERENCES "course"("courseid") ON DELETE CASCADE ON UPDATE NO ACTION;

-- AddForeignKey
ALTER TABLE "review" ADD CONSTRAINT "review_studentid_fkey" FOREIGN KEY ("studentid") REFERENCES "student"("userid") ON DELETE CASCADE ON UPDATE NO ACTION;

-- AddForeignKey
ALTER TABLE "student" ADD CONSTRAINT "student_userid_fkey" FOREIGN KEY ("userid") REFERENCES "User"("userid") ON DELETE CASCADE ON UPDATE NO ACTION;
