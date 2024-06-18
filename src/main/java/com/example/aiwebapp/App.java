package com.example.aiwebapp;

import spark.Spark;

public class App {
    public static void main(String[] args) {
        Spark.get("/", (req, res) -> {
            res.type("text/html");
            return "<h1>How AI is Changing the World</h1>" +
                   "<p>Artificial Intelligence (AI) is transforming every aspect of our lives...</p>";
        });
    }
}
