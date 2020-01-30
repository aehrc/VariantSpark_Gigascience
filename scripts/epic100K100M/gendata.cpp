#include <stdio.h>
#include <stdlib.h>
#include <string.h>

typedef unsigned char uint8;
typedef unsigned short int uint16;
typedef unsigned int uint32;
typedef unsigned long long int uint64;
typedef int int32;

#define ERROR(X)                                                                 \
    {                                                                            \
        printf("\n *** ERROR: %s (line:%u - File %s)\n", X, __LINE__, __FILE__); \
        exit(0);                                                                 \
    }
#define NULL_CHECK(X)                                                                         \
    {                                                                                         \
        if (!X)                                                                               \
        {                                                                                     \
            printf("\n *** ERROR: %s is null (line:%u - File %s)\n", #X, __LINE__, __FILE__); \
            exit(0);                                                                          \
        }                                                                                     \
    }

int rnd;

int main(int argc, char *argv[])
{
    if (argc != 8)
    {
        printf("usage %s numSample batchSize numBatch varNamelen seed rate outFile\n", argv[0]);
        return 0;
    }
    uint32 numSample = atoi(argv[1]);
    uint32 batchSize = atoi(argv[2]);
    uint32 numBatch = atoi(argv[3]);
    uint32 varNameLen = atoi(argv[4]);
    uint32 seed = atoi(argv[5]);
    uint32 rate = (atof(argv[6]) * 100000);
    char *outFile = argv[7];

    FILE *of = fopen(outFile, "wb");
    NULL_CHECK(of);

    srand(seed);
    rnd = 0;
    char format[10];
    sprintf(format, "v_%%0%uu", varNameLen - 2);
    uint32 vIdx = 0;

    // Write Header (sample ids)
    printf("varSam");
    fprintf(of, "varSam");
    for (uint32 i = 0; i < numSample; i++)
    {
        printf(",s_%u", i);
        fprintf(of, ",s_%u", i);
    }
    printf("\n");
    fprintf(of, "\n");

    // Allocate Data
    char *data = new char[batchSize * numSample];
    NULL_CHECK(data)

    // one line of csv
    uint32 csvLineSize = (numSample * 2) + varNameLen + 1;
    char *csvLine = new char[csvLineSize];
    NULL_CHECK(csvLine);

    memset(csvLine, '*', csvLineSize);
    csvLine[csvLineSize - 1] = '\n';
    for (uint32 i = csvLineSize - 3; i > varNameLen; i -= 2)
        csvLine[i] = ',';

    // data in csv format
    char *csv = new char[batchSize * csvLineSize];
    NULL_CHECK(csv);

    // prepare csv batch
    uint32 csvIdx = 0;
    for (uint32 i = 0; i < batchSize; i++)
    {
        sprintf(csvLine, format, 0);
        csvLine[varNameLen] = ',';
        strcpy(&csv[csvIdx], csvLine);
        csvIdx += csvLineSize;
    }

    // Fill Random
    for (uint32 i = 0; i < (batchSize * numSample); i++)
        data[i] = random();

    // Simulate and write all batches
    for (uint32 l = 0; l < numBatch; l++)
    {
        // Simulate using xor
        for (uint32 v = 0; v < batchSize; v++)
        {
            uint32 a = random() % batchSize;
            uint32 b = random() % batchSize;

            char *x = &data[a * numSample];
            char *y = &data[b * numSample];

            char *d = &data[v * numSample];

            for (uint32 s = 0; s < numSample; s++)
                d[s] = x[s] ^ y[s];
        }

        // data to csv
        char *xdata = data;
        char *xcsv = csv;
        for (uint32 v = 0; v < batchSize; v++)
        {
            // Write var id
            sprintf(xcsv, format, vIdx);
            vIdx++;
            xcsv[varNameLen] = ',';

            for (uint32 s = 0, p = csvLineSize - 2; s < numSample; s++, p -= 2)
            {
                // turn genotype to chr (0, 1 or 2) and handle 3 to be sequentinally 0, 1 or 2
                char gt = xdata[s] & 0x03;
                gt = (gt == 0x03) ? rnd++ : gt;
                if (rnd > 2)
                    rnd = 0;
                gt += '0';

                // write it in csv data
                xcsv[p] = gt;
            }
            xdata += numSample;
            xcsv += csvLineSize;
        }
        // Write batch
        fwrite(csv, 1, (batchSize * csvLineSize), stdout);
        // Write fraction of batches to output file
        if ((random() % 100000) < rate)
            fwrite(csv, 1, (batchSize * csvLineSize), of);
    }
    return 0;
}