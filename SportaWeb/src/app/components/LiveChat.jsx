import { ChevronRight, Send, Paperclip, Smile, Check, CheckCheck } from "lucide-react";
import { useState } from "react";
function LiveChat({ onBack }) {
  const [messageText, setMessageText] = useState("");
  const [messages, setMessages] = useState([
    {
      id: 1,
      text: "\u0645\u0631\u062D\u0628\u0627\u064B! \u0643\u064A\u0641 \u064A\u0645\u0643\u0646\u0646\u064A \u0645\u0633\u0627\u0639\u062F\u062A\u0643 \u0627\u0644\u064A\u0648\u0645\u061F",
      sender: "support",
      time: "10:30 \u0635\u0628\u0627\u062D\u0627\u064B"
    },
    {
      id: 2,
      text: "\u0645\u0631\u062D\u0628\u0627\u064B\u060C \u0644\u062F\u064A \u0633\u0624\u0627\u0644 \u0639\u0646 \u0627\u0644\u062D\u062C\u0648\u0632\u0627\u062A",
      sender: "user",
      time: "10:32 \u0635\u0628\u0627\u062D\u0627\u064B",
      status: "read"
    },
    {
      id: 3,
      text: "\u0628\u0627\u0644\u062A\u0623\u0643\u064A\u062F! \u0633\u0623\u0643\u0648\u0646 \u0633\u0639\u064A\u062F\u0627\u064B \u0628\u0645\u0633\u0627\u0639\u062F\u062A\u0643. \u0645\u0627 \u0647\u0648 \u0633\u0624\u0627\u0644\u0643\u061F",
      sender: "support",
      time: "10:32 \u0635\u0628\u0627\u062D\u0627\u064B"
    }
  ]);
  const handleSendMessage = () => {
    if (messageText.trim()) {
      const newMessage = {
        id: messages.length + 1,
        text: messageText,
        sender: "user",
        time: (/* @__PURE__ */ new Date()).toLocaleTimeString("ar-SA", { hour: "2-digit", minute: "2-digit" }),
        status: "sent"
      };
      setMessages([...messages, newMessage]);
      setMessageText("");
      setTimeout(() => {
        const autoReply = {
          id: messages.length + 2,
          text: "\u0634\u0643\u0631\u0627\u064B \u0644\u0631\u0633\u0627\u0644\u062A\u0643. \u0633\u064A\u0642\u0648\u0645 \u0623\u062D\u062F \u0645\u0645\u062B\u0644\u064A \u062E\u062F\u0645\u0629 \u0627\u0644\u0639\u0645\u0644\u0627\u0621 \u0628\u0627\u0644\u0631\u062F \u0639\u0644\u064A\u0643 \u0641\u064A \u0623\u0642\u0631\u0628 \u0648\u0642\u062A \u0645\u0645\u0643\u0646.",
          sender: "support",
          time: (/* @__PURE__ */ new Date()).toLocaleTimeString("ar-SA", { hour: "2-digit", minute: "2-digit" })
        };
        setMessages((prev) => [...prev, autoReply]);
      }, 1500);
    }
  };
  const handleKeyPress = (e) => {
    if (e.key === "Enter" && !e.shiftKey) {
      e.preventDefault();
      handleSendMessage();
    }
  };
  return <div className="flex-1 flex flex-col bg-gray-50 h-screen">
      {
    /* Header */
  }
      <div className="bg-gradient-to-br from-primary to-primary/90 text-white px-6 py-4 shadow-lg">
        <div className="flex items-center gap-3">
          <button onClick={onBack} className="p-2 bg-white/20 rounded-full backdrop-blur-sm hover:bg-white/30 transition-colors">
            <ChevronRight className="w-5 h-5" />
          </button>
          <div className="flex items-center gap-3 flex-1">
            <div className="w-10 h-10 bg-white/20 rounded-full flex items-center justify-center">
              <span className="text-lg">💬</span>
            </div>
            <div>
              <h1 className="text-base font-medium">دعم SPORTA</h1>
              <div className="flex items-center gap-2">
                <div className="w-2 h-2 bg-green-400 rounded-full" />
                <p className="text-xs text-white/80">متصل الآن</p>
              </div>
            </div>
          </div>
        </div>
      </div>

      {
    /* Messages Area */
  }
      <div className="flex-1 overflow-y-auto px-4 py-4 space-y-4">
        {
    /* Date Separator */
  }
        <div className="flex justify-center">
          <div className="bg-white/80 backdrop-blur-sm px-3 py-1 rounded-full shadow-sm">
            <p className="text-xs text-muted-foreground">اليوم</p>
          </div>
        </div>

        {messages.map((message) => <div
    key={message.id}
    className={`flex ${message.sender === "user" ? "justify-start" : "justify-end"}`}
  >
            <div
    className={`max-w-[75%] ${message.sender === "user" ? "bg-white border border-border" : "bg-gradient-to-br from-primary to-primary/90 text-white"} rounded-2xl px-4 py-3 shadow-sm`}
  >
              <p className="text-sm leading-relaxed">{message.text}</p>
              <div className="flex items-center justify-end gap-1 mt-1">
                <p className={`text-xs ${message.sender === "user" ? "text-muted-foreground" : "text-white/70"}`}>
                  {message.time}
                </p>
                {message.sender === "user" && message.status && <div>
                    {message.status === "sent" && <Check className="w-3 h-3 text-gray-400" />}
                    {message.status === "delivered" && <CheckCheck className="w-3 h-3 text-gray-400" />}
                    {message.status === "read" && <CheckCheck className="w-3 h-3 text-primary" />}
                  </div>}
              </div>
            </div>
          </div>)}

        {
    /* Typing Indicator (optional) */
  }
        {
    /* <div className="flex justify-end">
      <div className="bg-white/80 backdrop-blur-sm rounded-2xl px-4 py-3 shadow-sm">
        <div className="flex gap-1">
          <div className="w-2 h-2 bg-gray-400 rounded-full animate-bounce" style={{ animationDelay: '0ms' }}></div>
          <div className="w-2 h-2 bg-gray-400 rounded-full animate-bounce" style={{ animationDelay: '150ms' }}></div>
          <div className="w-2 h-2 bg-gray-400 rounded-full animate-bounce" style={{ animationDelay: '300ms' }}></div>
        </div>
      </div>
    </div> */
  }
      </div>

      {
    /* Quick Replies */
  }
      <div className="px-4 py-2 bg-white border-t border-border">
        <div className="flex gap-2 overflow-x-auto pb-2">
          <button
    onClick={() => setMessageText("\u0643\u064A\u0641 \u064A\u0645\u0643\u0646\u0646\u064A \u062D\u062C\u0632 \u0645\u0644\u0639\u0628\u061F")}
    className="px-3 py-1.5 bg-gray-100 text-secondary text-xs rounded-full hover:bg-gray-200 transition-colors whitespace-nowrap"
  >
            حجز ملعب
          </button>
          <button
    onClick={() => setMessageText("\u0645\u0627 \u0647\u064A \u0634\u0631\u0648\u0637 \u0627\u0644\u0625\u0644\u063A\u0627\u0621\u061F")}
    className="px-3 py-1.5 bg-gray-100 text-secondary text-xs rounded-full hover:bg-gray-200 transition-colors whitespace-nowrap"
  >
            شروط الإلغاء
          </button>
          <button
    onClick={() => setMessageText("\u0644\u062F\u064A \u0645\u0634\u0643\u0644\u0629 \u0641\u064A \u0627\u0644\u062F\u0641\u0639")}
    className="px-3 py-1.5 bg-gray-100 text-secondary text-xs rounded-full hover:bg-gray-200 transition-colors whitespace-nowrap"
  >
            مشكلة دفع
          </button>
        </div>
      </div>

      {
    /* Input Area */
  }
      <div className="bg-white px-4 py-3 border-t border-border shadow-lg">
        <div className="flex items-end gap-2">
          <button className="p-2 hover:bg-gray-100 rounded-full transition-colors">
            <Paperclip className="w-5 h-5 text-gray-500" />
          </button>
          <button className="p-2 hover:bg-gray-100 rounded-full transition-colors">
            <Smile className="w-5 h-5 text-gray-500" />
          </button>
          <div className="flex-1 bg-gray-100 rounded-2xl px-4 py-2">
            <textarea
    value={messageText}
    onChange={(e) => setMessageText(e.target.value)}
    onKeyPress={handleKeyPress}
    placeholder="اكتب رسالتك..."
    className="w-full bg-transparent text-sm text-secondary placeholder:text-muted-foreground resize-none outline-none"
    rows={1}
    style={{ maxHeight: "100px" }}
  />
          </div>
          <button
    onClick={handleSendMessage}
    disabled={!messageText.trim()}
    className={`p-3 rounded-full transition-all ${messageText.trim() ? "bg-gradient-to-br from-primary to-primary/90 text-white hover:shadow-lg" : "bg-gray-200 text-gray-400 cursor-not-allowed"}`}
  >
            <Send className="w-5 h-5" />
          </button>
        </div>
      </div>

      {
    /* Info Banner */
  }
      <div className="bg-blue-50 border-t border-blue-200 px-4 py-2">
        <p className="text-xs text-center text-muted-foreground">
          أوقات العمل: السبت - الخميس، 9:00 صباحاً - 6:00 مساءً
        </p>
      </div>
    </div>;
}
export {
  LiveChat as default
};
