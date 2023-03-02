//
//  ContentView.swift
//  iOS_CoreImage
//
//  Created by Niklas Diekhöner on 19.02.23.
//

import CoreImage
import CoreImage.CIFilterBuiltins
import SwiftUI

struct ContentView: View {
    
    @State private var image: Image?
    @State private var filterIntensity = 0.0
    @State private var hueIntensity = 0.5
    @State private var saturationIntensity = 0.5
    @State private var luminanceIntensity = 0.5
    @State private var contrasteIntensity = 0.5

    @State private var showingImagePicker = false
    @State private var inputImage: UIImage?
    @State private var processedImage: UIImage?

    @State private var choosableFilter: CIFilter = CIFilter.sepiaTone()
    @State private var hueFilter: CIFilter = CIFilter.hueAdjust()
    @State private var colorControlsFilter: CIFilter = CIFilter.colorControls()
    let context = CIContext()

    @State private var showingFilterSheet = false

    // MARK: GUI
    
    var body: some View {
        NavigationView {
            VStack {
                // stacking elements over each other
                ZStack {
                    Rectangle()
                        .fill(.secondary)

                    Text("Tap to select a picture")
                        .foregroundColor(.white)
                        .font(.headline)

                    image?
                        .resizable()
                        .scaledToFit()
                }
                .onTapGesture {
                    showingImagePicker = true
                }

                // sliders for adjusting the filters
                HStack {
                    Text("Hue").frame(maxWidth: 100)
                    Slider(value: $hueIntensity)
                        .onChange(of: hueIntensity) { _ in applyProcessing() }
                }
                
                HStack {
                    Text("Saturation").frame(maxWidth: 100)
                    Slider(value: $saturationIntensity)
                        .onChange(of: saturationIntensity) { _ in applyProcessing() }
                }
                
                HStack {
                    Text("Luminance").frame(maxWidth: 100)
                    Slider(value: $luminanceIntensity)
                        .onChange(of: luminanceIntensity) { _ in applyProcessing() }
                }
                
                HStack {
                    Text("Contrast").frame(maxWidth: 100)
                    Slider(value: $contrasteIntensity)
                        .onChange(of: contrasteIntensity) { _ in applyProcessing() }
                }
                
                HStack {
                    Text("Intensity").frame(maxWidth: 100)
                    Slider(value: $filterIntensity)
                        .onChange(of: filterIntensity) { _ in applyProcessing() }
                }
                .padding(.vertical)

                // buttons
                HStack {
                    Button("Change Filter") {
                        showingFilterSheet = true
                    }
                    Spacer()
                    Button("Reset") {
                        filterIntensity = 0.0
                        hueIntensity = 0.5
                        saturationIntensity = 0.5
                        luminanceIntensity = 0.5
                        contrasteIntensity = 0.5
                    }
                    Spacer()
                    Button("Save", action: save)
                }
            }
            .padding([.horizontal, .bottom])
            .navigationTitle("CoreImage")
            .onChange(of: inputImage) { _ in loadImage() }
            .sheet(isPresented: $showingImagePicker) {
                ImagePicker(image: $inputImage)
            }
            // confirmationDialog for selecting a chooseable filter
            .confirmationDialog("Select a filter", isPresented: $showingFilterSheet) {
                Button("Crystallize") { setFilter(CIFilter.crystallize()) }
                Button("Edges") { setFilter(CIFilter.edges()) }
                Button("Gaussian Blur") { setFilter(CIFilter.gaussianBlur()) }
                Button("Pixellate") { setFilter(CIFilter.pixellate()) }
                Button("Sepia Tone") { setFilter(CIFilter.sepiaTone()) }
                Button("Unsharp Mask") { setFilter(CIFilter.unsharpMask()) }
                Button("Vignette") { setFilter(CIFilter.vignette()) }
                Button("Cancel", role: .cancel) { }
            }
        }
    }

    // loads a image from the photos app
    func loadImage() {
        guard let inputImage = inputImage else { return }

        let beginImage = CIImage(image: inputImage)
        choosableFilter.setValue(beginImage, forKey: kCIInputImageKey)
        applyProcessing()
    }

    // saves the image to the photos app
    func save() {
        guard let processedImage = processedImage else { return }

        let imageSaver = ImageSaver()

        imageSaver.successHandler = {
            print("Success!")
        }

        imageSaver.errorHandler = {
            print("Oops! \($0.localizedDescription)")
        }

        imageSaver.writeToPhotoAlbum(image: processedImage)
    }
    
    // MARK: CIFilter

    // applies all filters
    func applyProcessing() {
        // get choosen filter parameter
        let inputKeys = choosableFilter.inputKeys

        // set chooseable filter parameters based on slider value
        // different chooseable filter have different parameters
        if inputKeys.contains(kCIInputIntensityKey) {
            choosableFilter.setValue(filterIntensity, forKey: kCIInputIntensityKey) // 0 ... 1
        }
        if inputKeys.contains(kCIInputRadiusKey) {
            choosableFilter.setValue(filterIntensity * 100, forKey: kCIInputRadiusKey) // 0 ... 100
        }
        if inputKeys.contains(kCIInputScaleKey) {
            choosableFilter.setValue(filterIntensity * 10, forKey: kCIInputScaleKey) // 0 ... 10
        }
        
        // set filters parameters based on slider value
        hueFilter.setValue((hueIntensity * 6.28319) - 3.141595, forKey: kCIInputAngleKey) // - 3.141595 ... 3.141595
        colorControlsFilter.setValue((saturationIntensity * 2), forKey: kCIInputSaturationKey) // 0 ... 2
        colorControlsFilter.setValue(luminanceIntensity - 0.5, forKey: kCIInputBrightnessKey) // -0.5 ... 0.5
        colorControlsFilter.setValue(contrasteIntensity + 0.5, forKey: kCIInputContrastKey) // 0.5 ... 1.5
                
        // apply chooseable filter
        guard let filterImage = choosableFilter.outputImage else { return }
        
        // apply hue filter
        hueFilter.setValue(filterImage, forKey: kCIInputImageKey)
        guard let hueImage = hueFilter.outputImage else { return }
        
        // apply colorControls filter
        colorControlsFilter.setValue(hueImage, forKey: kCIInputImageKey)
        guard let outputImage = colorControlsFilter.outputImage else { return }

        // MARK: CIContext
        
        // convert filter to Image and UIImage
        if let cgimg = context.createCGImage(outputImage, from: outputImage.extent) {
            let uiImage = UIImage(cgImage: cgimg)
            image = Image(uiImage: uiImage)
            processedImage = uiImage
        }
    }

    // sets the choosen filter
    func setFilter(_ filter: CIFilter) {
        choosableFilter = filter
        loadImage()
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
