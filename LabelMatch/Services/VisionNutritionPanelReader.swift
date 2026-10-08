import Foundation
import Vision

/// Reads text from a photo on the device with Vision.
/// Nothing is uploaded.
struct VisionNutritionPanelReader: NutritionPanelReader {

    func recognisedLines(in imageData: Data) throws -> [String] {
        let request = VNRecognizeTextRequest()
        request.recognitionLevel = .accurate
        request.usesLanguageCorrection = false

        let handler = VNImageRequestHandler(data: imageData, options: [:])
        try handler.perform([request])

        let observations = request.results ?? []
        return joinIntoRows(observations)
    }

    // A label is a table. Vision may return each cell on its own,
    // so we put the pieces that sit on the same row back together.
    private func joinIntoRows(_ observations: [VNRecognizedTextObservation]) -> [String] {
        var pieces: [(text: String, left: CGFloat, middle: CGFloat, height: CGFloat)] = []
        for observation in observations {
            guard let text = observation.topCandidates(1).first?.string else { continue }
            let box = observation.boundingBox
            pieces.append((text, box.minX, box.midY, box.height))
        }

        // Vision counts from the bottom, so the highest middle is the top row.
        pieces.sort { $0.middle > $1.middle }

        var rows: [[(text: String, left: CGFloat)]] = []
        var rowMiddle: CGFloat = 0
        var rowHeight: CGFloat = 0

        for piece in pieces {
            if !rows.isEmpty && abs(piece.middle - rowMiddle) < rowHeight * 0.6 {
                rows[rows.count - 1].append((piece.text, piece.left))
            } else {
                rows.append([(piece.text, piece.left)])
                rowMiddle = piece.middle
                rowHeight = piece.height
            }
        }

        return rows.map { row in
            row.sorted { $0.left < $1.left }
                .map { $0.text }
                .joined(separator: " ")
        }
    }
}
