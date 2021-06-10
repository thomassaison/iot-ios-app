//
//  ContentView.swift
//  iot-app
//
//  Created by thomas saison on 10/06/2021.
//

import SwiftUI
import Moscapsule


class Esp32MqttClient: ObservableObject {
    var mqttConfig: MQTTConfig
    var mqttClient: MQTTClient? = nil
    
    @Published var temperature: String = ""
    @Published var ledState: Bool = false

    init() {
        mqttConfig = MQTTConfig(clientId: "19190190189", host: "15.188.51.116", port: 1883, keepAlive: 60);
        
        mqttConfig.onConnectCallback = { returnCode in
            NSLog("Return Code is \(returnCode.description)")
        }

        mqttConfig.onMessageCallback = { [self ] mqttMessage in
            if mqttMessage.topic == "temperature" {
                DispatchQueue.main.async {
                    self.temperature = mqttMessage.payloadString! + " °C"
                }
            } else if mqttMessage.topic == "led" {
                DispatchQueue.main.async {
                    if (mqttMessage.payloadString == "on") {
                        self.ledState = true
                    } else {
                        self.ledState = false
                    }
                    print(ledState)
                }
            }
        }
        
        mqttClient = MQTT.newConnection(mqttConfig)
        subscribe(topic: "temperature")
        subscribe(topic: "led")
    }
    
    func subscribe(topic: String) {
        mqttClient?.subscribe(topic, qos: 2)
    }
    
    func publish(message: String, topic: String) {
        mqttClient?.publish(string: message, topic: topic, qos: 2, retain: true)
    }
    
    func changeLedState() {
        if (ledState == true) {
            publish(message: "off", topic: "led")
        } else {
            publish(message: "on", topic: "led")
        }
    }
}

struct ContentView: View {
    @ObservedObject private var mqttClient = Esp32MqttClient()
    var body: some View {
        NavigationView {
            Form {
                HStack {
                    Text("Temperature")
                    Spacer()
                    Text(self.mqttClient.temperature)
                }
                Toggle(isOn: self.$mqttClient.ledState) {
                    Text("Led")
                }.disabled(/*@START_MENU_TOKEN@*/true/*@END_MENU_TOKEN@*/)
                
                Section {
                    Button("Change led state") {
                        self.mqttClient.changeLedState()
                    }
                }
            }
            .navigationBarTitle("ESP 32 MANAGER")
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
