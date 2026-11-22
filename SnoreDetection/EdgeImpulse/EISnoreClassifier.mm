#include "EISnoreClassifier.h"

#include <cstring>
#include "edge-impulse-sdk/classifier/ei_run_classifier.h"

EISnoreResult EISnoreClassify(const float *samples, size_t sampleCount) {
    EISnoreResult output = {
        .success = false,
        .isSnore = false,
        .snoringConfidence = 0.0f,
        .noSnoringConfidence = 0.0f,
        .errorCode = EI_IMPULSE_OK
    };

    if (samples == nullptr || sampleCount != EI_CLASSIFIER_RAW_SAMPLE_COUNT) {
        output.errorCode = EI_IMPULSE_DSP_ERROR;
        return output;
    }

    signal_t signal;
    const int signalError = numpy::signal_from_buffer(
        const_cast<float *>(samples),
        sampleCount,
        &signal
    );
    if (signalError != EI_IMPULSE_OK) {
        output.errorCode = static_cast<int>(signalError);
        return output;
    }

    ei_impulse_result_t result = {};
    EI_IMPULSE_ERROR classifierError = run_classifier(&signal, &result, false);
    if (classifierError != EI_IMPULSE_OK) {
        output.errorCode = classifierError;
        return output;
    }

    for (size_t index = 0; index < EI_CLASSIFIER_LABEL_COUNT; index++) {
        const char *label = result.classification[index].label;
        const float value = result.classification[index].value;

        if (std::strcmp(label, "Snoring") == 0) {
            output.snoringConfidence = value;
        } else if (std::strcmp(label, "No Snoring") == 0) {
            output.noSnoringConfidence = value;
        }
    }

    output.success = true;
    output.isSnore = output.snoringConfidence >= output.noSnoringConfidence;
    return output;
}
