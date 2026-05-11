get formattedTime() {
    try {
        const entryPayload = JSON.parse(this.conversationEntry?.entryPayload || '{}');
        const timestamp = entryPayload.timestamp || this.conversationEntry?.timestamp;
        if (timestamp) {
            const date = new Date(timestamp);
            return date.toLocaleTimeString([], { 
                hour: '2-digit', 
                minute: '2-digit' 
            });
        }
    } catch (e) {
        return '';
    }
    return '';
}
