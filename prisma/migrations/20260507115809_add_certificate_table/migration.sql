-- CreateTable
CREATE TABLE "certificate" (
    "certificateid" SERIAL NOT NULL,
    "issuedate" DATE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "studentid" INTEGER NOT NULL,
    "courseid" INTEGER NOT NULL,

    CONSTRAINT "certificate_pkey" PRIMARY KEY ("certificateid")
);

-- CreateIndex
CREATE UNIQUE INDEX "certificate_studentid_courseid_key" ON "certificate"("studentid", "courseid");

-- AddForeignKey
ALTER TABLE "certificate" ADD CONSTRAINT "certificate_studentid_fkey" FOREIGN KEY ("studentid") REFERENCES "student"("userid") ON DELETE CASCADE ON UPDATE NO ACTION;

-- AddForeignKey
ALTER TABLE "certificate" ADD CONSTRAINT "certificate_courseid_fkey" FOREIGN KEY ("courseid") REFERENCES "course"("courseid") ON DELETE CASCADE ON UPDATE NO ACTION;
