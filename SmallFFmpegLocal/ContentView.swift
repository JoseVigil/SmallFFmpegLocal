//
//  ContentView.swift
//  SmallFFmpegLocal
//
//  Created by Jose Vigil on 05/12/2024.
//

//
//  ContentView.swift
//  SmallFFmpeg
//
//  Created by Jose Vigil on 03/12/2024.
//import SwiftUI

//https://www.bannerbear.com/blog/how-to-add-subtitles-to-a-video-file-using-ffmpeg/

import SwiftUI
import AVKit
import ffmpegkit
import Foundation

struct ContentView: View {
    @State private var projectDirectory: String = Bundle.main.bundlePath + "/assets"

    @State private var videoPath: String = ""
    @State private var logoImagePath: String = ""
    @State private var frameImagePath: String = ""
    @State private var imagePath: String = ""
    @State private var image1Path: String = ""
    @State private var puzzleImagePath: String = ""
    @State private var assStylePath: String = ""
    @State private var fontDirectory: String = ""

    @State private var outputVideoPath: String = {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyyMMdd_HHmmss"
        let timestamp = dateFormatter.string(from: Date())
        return Bundle.main.bundlePath + "/../assets/render/result_\(timestamp).mp4"
    }()

    @State private var command: String = ""
    @State private var resultMessage: String = ""
    @State private var logOutput: String = ""

    @State private var player: AVPlayer? = nil

    var body: some View {
        VStack {
            HStack {
                VStack {
                    Form {
                        Section(header: Text("Project Directory")) {
                            Text(projectDirectory)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                        }

                        Section(header: Text("Video Input Path")) {
                            Text(videoPath)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                        }

                        Section(header: Text("ASS Style File Path")) {
                            Text(assStylePath)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                        }

                        Section(header: Text("Image Path for Overlay")) {
                            Text(imagePath)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                        }
                    }
                    .frame(maxWidth: getScreenWidth() * 0.4)
                    .padding(.top)

                    Button(action: {
                        updateCommand()
                    }) {
                        Text("Check Command")
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding()
                            .background(Color.orange)
                            .cornerRadius(10)
                    }
                    .padding(.top)

                    Button(action: {
                        runFFmpegCommand()
                    }) {
                        Text("Burn Video")
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding()
                            .background(Color.blue)
                            .cornerRadius(10)
                    }
                    .padding(.top)

                    ScrollView {
                        TextEditor(text: $command)
                            .font(.system(size: 14, weight: .medium, design: .monospaced))
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(30)
                    }
                    .frame(height: 200)

                    ScrollView {
                        TextEditor(text: $logOutput)
                            .font(.system(size: 12, weight: .medium, design: .monospaced))
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .foregroundColor(.red)
                            .padding(30)
                    }
                    .frame(height: 450)
                }
                .frame(maxWidth: 500)

                if !outputVideoPath.isEmpty {
                    VStack {
                        Text("Output Video Preview")
                            .font(.headline)
                            .padding(.top)

                        if let player = player {
                            VideoPlayer(player: player)
                                .frame(maxWidth: 500, maxHeight: 800)
                                .onAppear {
                                    player.play()
                                }
                        } else {
                            Rectangle()
                                .fill(Color.gray.opacity(0.2))
                                .frame(maxWidth: 500, maxHeight: 800)
                                .overlay(
                                    Text("No video loaded")
                                        .foregroundColor(.black)
                                )
                        }
                    }
                    .padding(.top)
                }
            }
        }
        .onAppear {
            updatePaths()
        }
    }

    private func updatePaths() {
        let sourceFilePath = URL(fileURLWithPath: #file)
        let repoPath = sourceFilePath.deletingLastPathComponent().deletingLastPathComponent()
        let assetsPath = repoPath.appendingPathComponent("assets")
        videoPath = assetsPath.appendingPathComponent("videos/trimmed_video_20250109_081718.mp4").path
        logoImagePath = assetsPath.appendingPathComponent("images/picker_image_2025010929081629_59.jpg").path
        frameImagePath = assetsPath.appendingPathComponent("images/picker_image_2025010929081629_48.jpg").path
        imagePath = assetsPath.appendingPathComponent("images/picker_image_2025010930081630_14.jpg").path
        image1Path = assetsPath.appendingPathComponent("images/puzzle_image_group_2025010907081607_45.png").path
        //puzzleImagePath = assetsPath.appendingPathComponent("images/puzzle.png").path
        assStylePath = assetsPath.appendingPathComponent("aas/transcribed_aas_20250109_081723.ass").path
        fontDirectory = assetsPath.appendingPathComponent("font").path
        outputVideoPath = assetsPath.appendingPathComponent("render/result_\(Date().timeIntervalSince1970).mp4").path
        print("Video Path: \(videoPath)")
    }
    
    /*
     -i "/data/user/0/com.notimation.small/files/trimmed_video/trimmed_video_20250109_081718.mp4" -i "/data/user/0/com.notimation.small/files/picker_images/picker_image_2025010929081629_59.jpg" -i "/data/user/0/com.notimation.small/files/picker_images/picker_image_2025010929081629_48.jpg" -i "/data/user/0/com.notimation.small/files/picker_images/picker_image_2025010930081630_14.jpg" -i "/data/user/0/com.notimation.small/files/images/puzzle_image_group_2025010907081607_45.png" -filter_complex "[0:v]subtitles='/data/user/0/com.notimation.small/files/aas/transcribed_aas_20250109_081723.ass'[sub];[sub][1:v]overlay=100:800:enable='between(t,4,5)'[v1]; [v1][2:v]overlay=100:800:enable='between(t,7,8)'[v2]; [v2][3:v]overlay=100:800:enable='between(t,10,11)'[v3]; [v3][4:v]overlay=100:800:enable='between(t,14,16)'[v4]; [v4][out]" -map "[out]" -map 0:a -c:v libx264 -crf 23 -c:a copy "/data/user/0/com.notimation.small/files/rendered/rendered_video_subtitle_20250109_081733.mp4"
     */


    private func updateCommand() {
        command = """
        -i \(videoPath) \
        -i \(logoImagePath) \
        -i \(frameImagePath) \
        -i \(imagePath) \
        -i \(image1Path) \
        -filter_complex "[0:v]subtitles='\(assStylePath)'[sub]; \
        [sub][1:v]overlay=100:800:enable='between(t,2,3)'[v1]; [v1][2:v]overlay=0:0:enable='between(t,3,4)'[v2]; [v2][3:v]overlay=0:0:enable='between(t,4,5)'[v3]; [v3][4:v]overlay=0:0:enable='between(t,5,6)'[out]" -map "[out]" -map 0:a -c:v libx264 -crf 23 -c:a copy \
        \(outputVideoPath)
        """
        
        /*command = """
        -i \(videoPath) \
        -i \(logoImagePath) \
        -i \(frameImagePath) \
        -i \(imagePath) \
        -i \(image1Path) \
        -i \(puzzleImagePath) \
        -filter_complex "[0:v]subtitles='\(assStylePath)'[sub]; \
        [sub][1:v]overlay=W-w-10:H-h-10[logo]; \
        [logo][2:v]overlay=0:0[frame]; \
        [frame][5:v]overlay=100:800:enable='between(t,7,10)'[puzzle]; \
        [puzzle][3:v]overlay=0:0:enable='between(t,5,7)'[img_overlay1]; \
        [img_overlay1][4:v]overlay=0:0:enable='between(t,10,12)'[final]" \
        -map "[final]" -map 0:a \
        -c:v libx264 -crf 23 -preset veryfast -c:a copy \
        \(outputVideoPath)
        """*/
    }

    private func runFFmpegCommand() {
        if command.isEmpty {
            updateCommand()
        }

        let dictionary: NSDictionary = [
            "name": "consola",
            "name": "futura"
        ]

        FFmpegKitConfig.setFontDirectory(fontDirectory, with: dictionary as? [AnyHashable: Any])

        logOutput = ""
        FFmpegKit.executeAsync(command) { session in
            let returnCode = session?.getReturnCode()
            DispatchQueue.main.async {
                if returnCode?.isValueSuccess() == true {
                    resultMessage = "Success! Video saved to \(outputVideoPath)"
                    DispatchQueue.main.async {
                        self.player = AVPlayer(url: URL(fileURLWithPath: self.outputVideoPath))
                    }
                } else {
                    resultMessage = "Error: \(session?.getLogsAsString() ?? "Unknown error")"
                }
                logOutput = session?.getOutput() ?? "No logs available."
            }
        }
    }

    private func getScreenWidth() -> CGFloat {
        NSScreen.main?.frame.width ?? 800
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
