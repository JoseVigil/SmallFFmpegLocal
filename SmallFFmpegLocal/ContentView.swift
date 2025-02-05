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

import SwiftUI
import AppKit // Asegúrate de importar AppKit para usar NSPasteboard

struct ContentView: View {
    @State private var logOutput: String = ""
    @State private var player = AVPlayer()
    @State private var command: String = ""

    var body: some View {
        HStack(spacing: 10) {
            VStack(alignment: .leading, spacing: 10) {
                VideoPlayer(player: player)
                    .frame(height: 600)
                
                Text("FFmpeg Command:")
                    .font(.headline)
                
                TextEditor(text: $command)
                    .font(.system(size: 12, weight: .medium, design: .monospaced))
                    .frame(height: 200)
                    .border(Color.gray, width: 1)
                    .padding(5)
                    .onChange(of: command) { newValue in
                        // Forzar el cursor al final del texto
                        DispatchQueue.main.async {
                            let endPosition = newValue.endIndex
                            command = newValue
                            // Mover el cursor al final
                            if let textView = NSApp.windows.first?.contentView?.subviews.first(where: { $0 is NSTextView }) as? NSTextView {
                                textView.setSelectedRange(NSRange(location: newValue.count, length: 0))
                            }
                        }
                    }
                
                HStack(spacing: 10) {
                    Button("Run Command") { runFFmpegCommand() }
                        .buttonStyle(ActionButtonStyle(color: .blue))
                    Button("Close") { NSApplication.shared.terminate(nil) }
                        .buttonStyle(ActionButtonStyle(color: .red))
                }
            }
            .frame(width: 600)
            .padding()
            
            ScrollViewReader { proxy in
                ScrollView {
                    Text(logOutput)
                        .font(.system(size: 12, weight: .medium, design: .monospaced))
                        .padding()
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
                        .textSelection(.enabled)
                        .id("logBottom")
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .border(Color.gray, width: 1)
                .padding(.trailing, 10)
                .onChange(of: logOutput) { _ in
                    DispatchQueue.main.async { proxy.scrollTo("logBottom", anchor: .bottom) }
                }
            }
        }
        .frame(width: 1500, height: 800)
        .padding()
        .onAppear {
            // Cargar y limpiar el contenido del portapapeles al iniciar la aplicación
            if let clipboardContent = NSPasteboard.general.string(forType: .string) {
                print("Contenido del portapapeles: [\(clipboardContent)]") // Depuración
                var cleanedContent = clipboardContent
                cleanedContent = cleanedContent.replacingOccurrences(of: "\r", with: "")
                cleanedContent = cleanedContent.replacingOccurrences(of: "\n", with: "")
                cleanedContent = cleanedContent.trimmingCharacters(in: .whitespacesAndNewlines)
                command = cleanedContent
            } else {
                print("No se pudo cargar el contenido del portapapeles.") // Depuración
            }
        }
    }
    
    private func cleanCommand(_ command: String) -> String {
        var cleanedCommand = command
        // Eliminar retornos de carro y saltos de línea
        cleanedCommand = cleanedCommand.replacingOccurrences(of: "\r", with: "")
        cleanedCommand = cleanedCommand.replacingOccurrences(of: "\n", with: "")
        // Eliminar espacios al principio y al final
        cleanedCommand = cleanedCommand.trimmingCharacters(in: .whitespacesAndNewlines)
        return cleanedCommand
    }
    
    private func runFFmpegCommand() {
        if command.isEmpty {
            logOutput = "Error: El comando está vacío."
            return
        }
        
        let cleanedCommand = cleanCommand(command)
        logOutput = "Executing command: \(cleanedCommand)\n"
        let outputVideoPath = extractOutputPath(from: cleanedCommand)
        
        // Ejecutar el comando con FFmpegKit
        FFmpegKit.executeAsync(cleanedCommand) { session in
            let returnCode = session?.getReturnCode()
            let newLog = session?.getOutput() ?? "No logs available."
            DispatchQueue.main.async {
                logOutput += "\n\(newLog)"
                if returnCode?.isValueSuccess() == true {
                    logOutput += "\n✅ Success! Video saved to \(outputVideoPath)"
                    
                    // Configurar el AVPlayer con el video generado
                    let videoURL = URL(fileURLWithPath: outputVideoPath)
                    player = AVPlayer(url: videoURL)
                    
                    // Asegurarse de que el video se reproduzca correctamente
                    player.play()
                } else {
                    logOutput += "\n❌ Error: \(session?.getLogsAsString() ?? "Unknown error")"
                }
            }
        } withLogCallback: { log in
            guard let logMessage = log?.getMessage() else { return }
            DispatchQueue.main.async {
                logOutput += "\(logMessage)\n"
            }
        } withStatisticsCallback: { stats in
            guard let stats = stats else { return }
            let progress = "⏳ Progress: \(stats.getTime()) ms, Speed: \(stats.getSpeed())x"
            DispatchQueue.main.async {
                logOutput += "\(progress)\n"
            }
        }
    }
    
    private func extractOutputPath(from command: String) -> String {
        let components = command.split(separator: " ")
        if let index = components.lastIndex(of: "-c:a"), index + 1 < components.count {
            return String(components[index + 2])
        }
        return ""
    }
}

struct ActionButtonStyle: ButtonStyle {
    let color: Color
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding()
            .background(color)
            .foregroundColor(.white)
            .cornerRadius(8)
            .opacity(configuration.isPressed ? 0.8 : 1)
    }
}
