#ifndef EISnoreClassifier_h
#define EISnoreClassifier_h

#include <stdbool.h>
#include <stddef.h>

#ifdef __cplusplus
extern "C" {
#endif

typedef struct {
    bool success;
    bool isSnore;
    float snoringConfidence;
    float noSnoringConfidence;
    int errorCode;
} EISnoreResult;

EISnoreResult EISnoreClassify(const float *samples, size_t sampleCount);

#ifdef __cplusplus
}
#endif

#endif
